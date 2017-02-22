# frozen_string_literal: true
require 'rails_helper'

feature 'Pool tubes at end of pipeline', js: true do
  has_a_working_api
  let(:user_uuid)             { 'user-uuid' }
  let(:user)                  { json :user, uuid: user_uuid }
  let(:user_swipecard)        { 'abcdef' }
  let(:tube_barcode)          { SBCF::SangerBarcode.new(prefix: 'NT', number: 1).machine_barcode.to_s }
  let(:sibling_barcode)       { '1234567890123' }
  let(:tube_uuid)             { SecureRandom.uuid }
  let(:sibling_uuid) { 'sibling-tube-0' }
  let(:child_purpose_uuid)    { 'child-purpose-0' }
  let(:example_tube)          { json(:tube_with_siblings, uuid: tube_uuid, siblings_count: 1, state: 'passed', barcode_number: 1) }
  let(:transfer_template_uuid) { 'transfer-template-uuid' }
  let(:transfer_template) { json :transfer_template, uuid: transfer_template_uuid }
  let(:multiplexed_library_tube_uuid) { 'multiplexed-library-tube-uuid' }

  let(:transfer_request) do
    stub_api_post(transfer_template_uuid,
                  payload: { transfer: { user: user_uuid, source: tube_uuid } },
                  body: json(:transfer_between_tubes_by_submission, destination: multiplexed_library_tube_uuid))
  end
  let(:transfer_request_b) do
    stub_api_post(transfer_template_uuid,
                  payload: { transfer: { user: user_uuid, source: sibling_uuid } },
                  body: json(:transfer_between_tubes_by_submission, destination: multiplexed_library_tube_uuid))
  end

  # Setup stubs
  background do
    Settings.transfer_templates['Transfer from tube to tube by submission'] = 'transfer-template-uuid'

    # Set-up the tube config
    Settings.purposes = {}
    Settings.purposes['example-purpose-uuid'] = {
      presenter_class: 'Presenters::SimpleTubePresenter',
      asset_type: 'Tube',
      name: 'Example Purpose'
    }
    Settings.purposes[child_purpose_uuid] = {
      presenter_class: 'Presenters::FinalTubePresenter',
      asset_type: 'Tube',
      name: 'Final Tube Purpose',
      form_class: 'Forms::FinalTubesForm',
      parents: ['Example Purpose']
    }
    # We look up the user
    stub_search_and_single_result('Find user by swipecard code', { 'search' => { 'swipecard_code' => user_swipecard } }, user)
    # We lookup the tube
    stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => tube_barcode } }, example_tube)
    # We get the actual tube
    stub_api_get(tube_uuid, body: example_tube)
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
    stub_api_get('transfer-template-uuid', body: json(:transfer_template, uuid: 'transfer-template-uuid'))
    # stub_api_get('stock-plate-purpose-uuid', body: json(:stock_plate_purpose))
    # stub_api_get('stock-plate-purpose-uuid', 'children', body: json(:plate_purpose_collection, size: 1))
    stub_api_get(multiplexed_library_tube_uuid, body: json(:multiplexed_library_tube))
    transfer_request
    transfer_request_b
  end

  scenario 'of a recognised type' do
    fill_in_swipecard_and_barcode user_swipecard, tube_barcode
    page_title = find('#tube-title')
    expect(page_title).to have_text('Example Purpose')
    click_on('Add an empty Final Tube Purpose tube')
    expect(page).to have_text('Multi Tube pooling')
    expect(page).to have_button('Make Tube', disabled: true)
    fill_in('Tube barcode', with: tube_barcode)
    find_field('Tube barcode').send_keys :tab
    fill_in('Tube barcode', with: sibling_barcode)
    find_field('Tube barcode').send_keys :tab
    click_on('Make Tube')
    expect(page).to have_content('New empty labware added to the system.')
    expect(transfer_request).to have_been_made.once
    expect(transfer_request_b).to have_been_made.once
  end

  def fill_in_swipecard_and_barcode(swipecard, barcode)
    visit root_path

    within '.content-main' do
      fill_in 'User Swipecard', with: swipecard
      find_field('User Swipecard').send_keys :enter
      expect(page).to have_content('Jane Doe')
      fill_in 'Plate or Tube Barcode', with: barcode
      find_field('Plate or Tube Barcode').send_keys :enter
    end
  end
end
