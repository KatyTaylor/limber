# frozen_string_literal: true

class Sequencescape::Api::V2::Well < Sequencescape::Api::V2::Base
  include Sequencescape::Api::V2::Shared::HasRequests
  has_many :qc_results
  has_many :requests_as_source, class_name: 'Sequencescape::Api::V2::Request'
  has_many :requests_as_target, class_name: 'Sequencescape::Api::V2::Request'
  has_many :downstream_assets, class_name: 'Sequencescape::Api::V2::Asset'
  has_many :downstream_tubes, class_name: 'Sequencescape::Api::V2::Tube'
  has_many :downstream_wells, class_name: 'Sequencescape::Api::V2::Well'
  has_many :downstream_plates, class_name: 'Sequencescape::Api::V2::Plate'

  has_many :upstream_assets, class_name: 'Sequencescape::Api::V2::Asset'
  has_many :upstream_tubes, class_name: 'Sequencescape::Api::V2::Tube'
  has_many :upstream_wells, class_name: 'Sequencescape::Api::V2::Well'
  has_many :upstream_plates, class_name: 'Sequencescape::Api::V2::Plate'
  has_many :aliquots, class_name: 'Sequencescape::Api::V2::Aliquot'

  has_many :transfer_requests_as_source, class_name: 'Sequencescape::Api::V2::TransferRequest'
  has_many :transfer_requests_as_target, class_name: 'Sequencescape::Api::V2::TransferRequest'

  def latest_concentration
    latest_qc(key: 'concentration', units: 'ng/ul')
  end

  def latest_molarity
    latest_qc(key: 'molarity', units: 'nM')
  end

  def latest_qc(key:, units:)
    qc_results.to_a # Convert to array to resolve any api queries. Otherwise select fails to work.
              .select { |qc| qc.key.casecmp(key).zero? }
              .select { |qc| qc.units.casecmp(units).zero? }
              .max_by(&:created_at)
  end

  def coordinate
    WellHelpers.well_coordinate(location)
  end

  def quadrant_index
    WellHelpers.well_quadrant(location)
  end

  def location
    position['name']
  end

  def tagged?
    aliquots.any?(&:tagged?)
  end

  def empty?
    aliquots.blank?
  end

  def passed?
    state == 'passed'
  end

  def failed?
    state == 'failed'
  end

  def suboptimal?
    aliquots.any?(&:suboptimal)
  end
end
