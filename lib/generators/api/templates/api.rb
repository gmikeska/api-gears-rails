require "api_gears"
<%= %Q(class #{api_classname} < ApiGears
  def initialize(**options)
    # if(options[:params].nil?) # use 'if' statements above the call to "super" if you need to set default params
    #   options[:params] = {}   # such as api_key, etc.
    # end
    # if(options[:currency].nil?)
    #   options[:currency] = "btc"
    # end
    # if(options[:chain_id].nil?)
    #   options[:chain_id] = "main"
    # end
    # options[:content_type] = "json"
    #{api_url}
    super(url,options)
    # endpoint "address_info", path:"/addrs/{address}"
    # endpoint "address_balance", path:"/addrs/{address}/balance"
    # endpoint "transaction", path:"/txs/{transaction_id}"
    # endpoint "generate_multisig_address", path:"/addrs",query_method: :post, query_params:[:pubkeys], set_query_params:{script_type:"multisig-2-of-3"}
  end
  # def request(**args) # If you need to transform all responses from this API in a certain way, you can override request,
  #   result = super    # just be sure to return the result!
  #   return result
  # end
end
 )%>
