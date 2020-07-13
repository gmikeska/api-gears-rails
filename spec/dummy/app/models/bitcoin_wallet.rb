require "byebug"
require_relative "application_record"
require_relative "../../lib/blockcypher_api"
class BitcoinWallet < ApplicationRecord
  sync_with :BlockcypherApi, currency:"btc", chain_id:"main", keys: :address
  sync_attr :address
  sync_attr :balance
  pull_endpoint :address_info
  pull_every 10.minutes

  after_api_pull do |data, wallet|
    # byebug
    data["balance"] = '%.8f' % (data["balance"].to_f/10000000)
    data
  end


end
