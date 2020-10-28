#cloud-config
#bootcmd (lines 2-19) can be removed when https://github.com/F5Networks/f5-declarative-onboarding/issues/129 is resolved. 
bootcmd:
  - touch /var/tmp/bootcmd_start
  - touch /config/custom-config.sh
  - echo "#!/bin/bash" >> /config/custom-config.sh
  - echo "touch /var/tmp/write_files_start" >> /config/custom-config.sh
  - echo "# Wait for MCPD to be up before running tmsh commands" >> /config/custom-config.sh
  - echo "source /usr/lib/bigstart/bigip-ready-functions" >> /config/custom-config.sh
  - echo "wait_bigip_ready" >> /config/custom-config.sh
  - echo "sleep 30" >> /config/custom-config.sh
  - echo "touch /var/tmp/custom_done" >> /config/custom-config.sh
  - echo "# Begin BIG-IP configuration" >> /config/custom-config.sh
  - echo "tmsh modify sys global-settings mgmt-dhcp disabled" >> /config/custom-config.sh
  - echo "tmsh save /sys config" >> /config/custom-config.sh
  - chmod +x /config/custom-config.sh
  - /config/custom-config.sh
  - touch /var/tmp/bootcmd_end
#cloud-config
tmos_declared:
  enabled: true
  icontrollx_trusted_sources: false
  icontrollx_package_urls:
    - "${DO_URL}"
    - "${AS3_URL}"
    - "${TS_URL}"
  do_declaration:
    schemaVersion: 1.0.0
    class: Device
    async: true
    label: Cloudinit Onboarding
    Common:
      class: Tenant
      hostname: ${bigip_hostname}
      provisioningLevels:
        class: Provision
        ltm: nominal
        asm: nominal
      poolLicense:
        class: License
        licenseType: licensePool
        bigIqHost: ${bigiq_license_host}
        bigIqUsername: ${bigiq_license_username}
        bigIqPassword: ${bigiq_license_password}
        licensePool: ${bigiq_license_licensepool}
        skuKeyword1: ${bigiq_license_skuKeyword1}
        skuKeyword2: ${bigiq_license_skuKeyword2}
        unitOfMeasure: ${bigiq_license_unitOfMeasure}
        hypervisor: ${bigiq_hypervisor}
        overwrite: true
        reachable: false
      dnsServers:
        class: DNS
        nameServers:
          - ${name_servers}
        search:
          - f5.com
      ntpServers:
        class: NTP
        servers:
          - ${ntp_servers}
      internal:
        class: VLAN
        mtu: 1500
        interfaces:
          - name: 1.2
            tagged: false
      internal-self:
        class: SelfIp
        address: ${internal_self_ip}/24
        vlan: internal
        allowService: default
        trafficGroup: traffic-group-local-only
      external:
        class: VLAN
        mtu: 1500
        interfaces:
          - name: 1.1
            tagged: false
      external-self:
        class: SelfIp
        address: ${external_self_ip}/24
        vlan: external
        allowService: none
        trafficGroup: traffic-group-local-only
      default:
        class: Route
        gw: 10.20.0.1
        network: default
        mtu: 1500
      dbvars:
        class: DbVariables
        ui.advisory.enabled: true
        ui.advisory.color: orange
        ui.advisory.text: This device is managed via automation.
      admin:
        class: User
        shell: bash
        userType: regular
  post_onboard_enabled: true
  post_onboard_commands:
    - "echo 'curl -s http://monitors.internal.local/rebooted' >> /config/startup"
    - "/usr/local/bin/f5mku -r ${F5_MASTER_KEY}"