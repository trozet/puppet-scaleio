# The set of facts about ScaleIO cluster.
# All facts expect that MDM IPs are available via the fact 'mdm_ips'.
# If mdm_ips is absent then it is expected that Master MDM is locally available.
# The facts about SDS/SDC and getting IPs from Gateway additionally expect that 
# MDM password is available via the fact 'mdm_password'.
# ---------------------------------------------------------------------------------
# |    Name                       | Description
# |--------------------------------------------------------------------------------
# | scaleio_mdm_ips               | Fact returns comma separated list of MDM IPs.
# | scaleio_mdm_names             | Fact returns comma separated list of MDM names.
# | scaleio_tb_ips                | Fact returns comma separated list of Tie-Breaker IPs.
# | scaleio_tb_names              | Fact returns comma separated list of Tie-Breaker names.
# | scaleio_sds_ips               | Fact returns comma separated list of SDS IPs.
# | scaleio_sds_names             | Fact returns comma separated list of SDS names.
# | scaleio_sdc_ips               | Fact returns comma separated list of SDC IPs,
# |                               | it is list of management IPs, not storage IPs.
# | scaleio_mdm_ips_from_gateway  | Fact returns comma separated list of MDM IP.
# |                               |   It requests them from Gateway via curl and requires
# |                               |   the fact 'gateway_ips'.
# |                               |   It uses 'admin' user by default or the fact 
# |                               |   'gateway_user' if it exists. It uses port 4443 or
# |                               |   the fact 'gateway_port' if it exists.


require 'facter'
require 'json'


# MDM IPs
mdm_ips = Facter.value(:mdm_ips)


# Register all facts for MDMs
# Map name of facts for MDM components to selection strings that are used in grep expression
mdm_components = {
  'scaleio_mdm_ips'           => ['\(Master MDM\)\|\(Slave MDMs\)', 'IPs:'],
  'scaleio_tb_ips'            => ['Tie-Breakers', 'IPs:'],
  'scaleio_mdm_names'         => ['\(Master MDM\)\|\(Slave MDMs\)', 'Name:'],
  'scaleio_tb_names'          => ['Tie-Breakers', 'Name:'],
}
mdm_components.each do |name, selector|
  Facter.add(name) do
    setcode do
      # Define mdm opts for SCLI tool to connect to ScaleIO cluster.
      # If there is no mdm_ips available it is expected to be run on a node with MDM Master. 
      if mdm_ips && mdm_ips != ''
        mdm_opts = []
        mdm_ips.split(',').each do |ip|
          mdm_opts.push("--mdm_ip %s" % ip)
        end
      else
        mdm_opts = ['']
      end      
      ip = nil
      # the cycle over MDM IPs because for query cluster SCLI's behaiveour is strange 
      # it works for one IP but doesn't for the list.
      mdm_opts.each do |opts|
        cmd = "scli %s --query_cluster --approve_certificate | grep  -A 2 '%s' | awk '/%s/ {print($2)}' | tr -d ','" % [opts, selector[0], selector[1]]
        res = Facter::Util::Resolution.exec(cmd)
        ip = res.split(' ').join(',') unless !res
      end
      ip
    end
  end
end


# Register all SDS/SDC facts
# Map SDC/SDS facts names to selection strings (the first string has 'include' semantic, the second - 'exclude')
sds_sdc_components = {
  'scaleio_sdc_ips'   => ['sdc', 'IP: [^ ]*', nil],
  'scaleio_sds_names' => ['sds', 'Name: [^ ]*', 'Protection Domain'],
  'scaleio_sds_ips'   => ['sds', 'IP: [^ ]*', 'Protection Domain'],
}
sds_sdc_components.each do |name, selector|
  Facter.add(name) do
    setcode do
      mdm_password = Facter.value(:mdm_password)
      if mdm_ips && mdm_ips != ''
        mdm_opts = "--mdm_ip %s" % mdm_ips
      else
        mdm_opts = ''
      end
      login_cmd = "scli %s --approve_certificate --login --username admin --password %s" % [mdm_opts, mdm_password]
      query_cmd = "scli %s --approve_certificate --query_all_%s" % [mdm_opts, selector[0]]
      result = Facter::Util::Resolution.exec("%s && %s" % [login_cmd, query_cmd])
      if result
        skip_cmd = ''
        if selector[2]
          skip_cmd = "grep -v '%s' | " % selector[2]
        end
        select_cmd = "%s grep -o '%s' | awk '{print($2)}'" % [skip_cmd, selector[1]]
        result = Facter::Util::Resolution.exec("echo '%s' | %s" % [result, select_cmd])
        if result
          result = result.split(' ')
          if result.count() > 0
            result = result.join(',')
          end
        end
      end
      result
    end
  end
end


#The fact about MDM IPs.
#It requests them from Gateway.
gw_ips    = Facter.value(:gateway_ips)
gw_passw  = Facter.value(:mdm_password)
if gw_passw && gw_passw != '' and gw_ips and gw_ips != ''
  Facter.add('scaleio_mdm_ips_from_gateway') do
    setcode do
      if Facter.value('gateway_user')
        gw_user      = Facter.value('gateway_user')
      else
        gw_user      = 'admin'
      end
      host        = gw_ips.split(',')[0]
      if Facter.value('gateway_port')
        port        = Facter.value('gateway_port')
      else
        port        = 4443
      end
      base_url    = "https://%s:%s/api/%s"
      login_url   = base_url % [host, port, 'login']
      config_url  = base_url % [host, port, 'Configuration']
      login_req   = "curl -k --basic --connect-timeout 5 --user #{gw_user}:#{gw_passw} #{login_url} 2>/dev/null | sed 's/\"//g'"
      token       = Facter::Util::Resolution.exec(login_req)
      if token && token != ''
        req_url     = "curl -k --basic --connect-timeout 5 --user #{gw_user}:#{token} #{config_url} 2>/dev/null"
        config_str  = Facter::Util::Resolution.exec(req_url)
        config      = JSON.parse(config_str)
        mdm_ips     = config['mdmAddresses'].join(',')
        mdm_ips
      else
        nil
      end
    end
  end
end
