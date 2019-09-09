# frozen_string_literal: true

# Tubes can be barcoded, but only have one receptacle for samples.
class Sequencescape::Api::V2::Tube < Sequencescape::Api::V2::Base
  include Sequencescape::Api::V2::Shared::HasRequests
  self.tube = true

  property :created_at, type: :time
  property :updated_at, type: :time
  property :labware_barcode, type: :barcode

  has_many :ancestors, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :descendants, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :parents, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :children, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class

  has_many :aliquots

  has_one :purpose

  DEFAULT_INCLUDES = [
    :purpose, 'aliquots.request.request_type'
  ].freeze

  def self.find_by(options, includes: DEFAULT_INCLUDES)
    Sequencescape::Api::V2::Tube.includes(*includes).find(options).first
  end

  # Dummied out for the moment. But no real reason not to add it to the API.
  def requests_as_source
    []
  end

  #
  # Override the model used in form/URL helpers
  # to allow us to treat old and new api the same
  #
  # @return [ActiveModel::Name] The resource behaves like a Limber::Tube
  #
  def model_name
    ::ActiveModel::Name.new(Limber::Tube, false)
  end

  # Currently us the uuid as our main identifier, might switch to human barcode soon
  def to_param
    uuid
  end

  def barcode
    labware_barcode
  end

  def stock_plate(purpose_names: SearchHelper.stock_plate_names)
    @stock_plate ||= ancestors.where(purpose_name: purpose_names).last
  end

  def human_barcode
    labware_barcode.human
  end
end
