require_relative '../rails_helper'

RSpec.describe BitcoinWallet, :type => :model do
  it "is valid with valid attributes" do
    expect(BitcoinWallet.new(address:"18cBEMRxXHqzWWCxZNtU91F5sbUNKhL5PX")).to be_valid
  end
  it "finds a bitcoin address balance" do
    wallet = BitcoinWallet.new(address:"18cBEMRxXHqzWWCxZNtU91F5sbUNKhL5PX")
    wallet.api_pull
    expect(wallet.balance.to_f).to be > 0
  end
  it "throws an error when called with a verb that hasn't been defined" do
    wallet = BitcoinWallet.new(address:"18cBEMRxXHqzWWCxZNtU91F5sbUNKhL5PX")

    expect{ wallet.api_create }.to raise_error(NoMethodError)
  end
end
