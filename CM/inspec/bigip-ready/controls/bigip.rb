title "Verify BIG-IP Application is Available"

alb_public_ip_address = attribute('ALB_PUBLIC_IP_ADDRESS')

control "Juice Shop is Ready" do
  impact 1.0
  title "Juice Shop is Ready"

  describe http("https://#{alb_public_ip_address}",
        method: 'GET',
        ssl_verify: false) do
    its('status') { should cmp 200 }
  end
end 