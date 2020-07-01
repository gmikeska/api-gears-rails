class BitcoinWallet < ApplicationRecord
  sync_with :BlockcypherApi, currency:"btc", chain_id:"main", keys: :address
  sync_attr :address
  sync_attr :balance
  pull_endpoint :address_info


end
