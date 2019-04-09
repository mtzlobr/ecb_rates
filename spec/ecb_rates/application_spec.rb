require 'spec_helper'
require 'timecop'

RSpec.describe EcbRates::Application do
  before do
    stub_request(:get, (EcbRates::TODAY_RATES)).
      to_return(status: 200, body: load_today_fixture)

    stub_request(:get, (EcbRates::HISTORY_RATES)).
      to_return(status: 200, body: load_history_fixture)

    stub_request(:get, (EcbRates::FULL_HISTORY_RATES)).
      to_return(status: 200, body: load_full_history_fixture)

    Timecop.freeze('2015-10-19')
  end

  after do
    Timecop.return
  end

  let(:app)      { EcbRates::Application.new }
  let(:currency) { EcbRates::VALID_CURRENCIES.first }

  describe 'exchange_rate' do
    context 'date == today' do
      it 'calls exchange_rate_for with current date and currency' do
        expect(app.today).to receive(:exchange_rate_for).
          with('JPY', Date.today)
        app.exchange_rate('JPY', Date.today)
      end
    end

    context 'date between yesterday and 90 days from now' do
      it 'calls exchange_rate_for with current date and currency' do
        expect(app.history).to receive(:exchange_rate_for).
          with('JPY', Date.today - 15)
        app.exchange_rate('JPY', Date.today - 15)
      end
    end

    context 'date older than 90 days from now' do
      it 'calls exchange_rate_for with current date and currency' do
        expect_any_instance_of(EcbRates::FullHistoryExchangeRates).to receive(:exchange_rate_for).
          with('JPY', Date.today - 92)
        app.exchange_rate('JPY', Date.today - 92)
      end
    end

    context 'date missing' do
      it "call exchange_rate_for with today's date and supplied currency" do
        expect(app.today).to receive(:exchange_rate_for).
          with('JPY', Date.today)
        app.exchange_rate('JPY')
      end
    end

    context 'currency_missing' do
      it 'raises CurrencyMissing exception' do
        expect { app.exchange_rate(nil) }.
          to raise_error EcbRates::CurrencyMissing
      end
    end

    context 'currency not supported' do
      it 'raises CurrencyNotSupported exception' do
        expect { app.exchange_rate('IMAGINARY') }.
          to raise_error EcbRates::CurrencyNotSupported
      end
    end
  end
end
