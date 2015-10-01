require 'java'
java_import 'burp.IBurpExtender'
java_import 'burp.IHttpListener'
java_import 'burp.IProxyListener'
java_import 'burp.IScannerListener'
java_import 'burp.IExtensionStateListener'

class BurpExtender
  include IBurpExtender, IHttpListener, IProxyListener, IScannerListener, IExtensionStateListener
  
  CERT = "/Users/abhisek/Codes/Misc/IBB/IBM/Tivoli_EM/data/keys/__ClientCertificate.crt"
  KEY = "/Users/abhisek/Codes/Misc/IBB/IBM/Tivoli_EM/data/keys/__ClientPrivateKey.pem"

  def	registerExtenderCallbacks(callbacks)
    @callbacks = callbacks
    @stdout = java.io.PrintWriter.new(callbacks.getStdout(), true)
    callbacks.setExtensionName("SMIME Signer")
    callbacks.registerHttpListener(self)
    callbacks.registerExtensionStateListener(self)

    @stdout.println("Extension is loaded")
    @stdout.println("CERT: #{CERT}")
    @stdout.println("KEY: #{KEY}")
  end
  
  def processHttpMessage(toolFlag, messageIsRequest, messageInfo)
    if (@callbacks.getToolName(toolFlag).to_s =~ /(intruder|repeater)/i) and messageIsRequest
      http_request = messageInfo.getRequest().to_s()
      if (http_request =~ /^POST/) and (http_request.index("This is an S/MIME signed message"))
        if http_request =~ /boundary="([^"]+)"/
          boundary = $1.to_s
          parts = http_request.split("--#{boundary}")
          http_body = parts[1].to_s.strip()
          http_headers = http_request.split("\r\n\r\n")[0].to_s.strip()
          modified_request = http_headers + "\r\n\r\n" + sign_request(http_body)
          #puts "====="
          #puts modified_request
          #puts "====="
          messageInfo.setRequest(modified_request.to_java_bytes())
          puts("[#{@callbacks.getToolName(toolFlag)}] Signed request size: #{modified_request.size}")
        end
      end
    end
  end

  def extensionUnloaded()
    @stdout.println("Extension was unloaded")
  end

  private

  def puts(s)
    @stdout.println(s)
  end

  def sign_request(data)
    res = ''
    IO.popen("openssl smime -sign -signer #{CERT} -inkey #{KEY}", "r+") do |pipe|
      pipe.write(data)
      pipe.close_write()
      until ((t = pipe.gets()).nil?); res << t; end
    end
    res
  end

end

      
