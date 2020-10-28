title "Verify BIG-IP Internal Availability"

control "ASM Master Key" do
  impact 1.0
  title "ASM Master Key is Set"
  desc "Ensure that the correct master key is set"

  only_if do
    file("/config/bigip.conf").exist?
  end

  describe command("f5mku -K") do
    its("stdout") { should match input("MASTER_KEY")}
  end
end