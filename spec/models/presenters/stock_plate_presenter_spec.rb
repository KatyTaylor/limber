# frozen_string_literal: true

RSpec.describe Presenters::StockPlatePresenter do
  has_a_working_api

  let(:labware) { create :v2_stock_plate }

  subject do
    Presenters::StockPlatePresenter.new(
      api: api,
      labware: labware
    )
  end

  let(:barcode_string) { 'DN2T' }

  it_behaves_like 'a stock presenter'
end
