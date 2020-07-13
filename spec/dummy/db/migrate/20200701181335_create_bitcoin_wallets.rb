class CreateBitcoinWallets < ActiveRecord::Migration[6.0]
  def change
    create_table :bitcoin_wallets do |t|
      t.string :address
      t.string :balance
      t.timestamp :synced_at
      t.timestamps
    end
  end
end
