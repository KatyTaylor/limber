# frozen_string_literal: true

class Limber::Plate < Sequencescape::Plate
  # Customize the has_many association to use out custom class.
  has_many :transfers_to_tubes, class_name: 'Limber::TubeTransfer'

  def library_type_name
    uuid = pools.keys.first
    uuid.nil? ? 'Unknown' : pools[uuid]['library_type']['name']
  end

  def number_of_pools
    pools.keys.count
  end

  def role
    label.prefix
  end

  def shearing_size
    uuid = pools.keys.first
    uuid.nil? ? 'Unknown' : pools[uuid]['insert_size'].to_a.join(' ')
  end

  def purpose
    plate_purpose
  end

  # We know that if there are any transfers with this plate as a source then they are into
  # tubes.
  def transfers_to_tubes?
    transfer_request_collections.present? || transfers_to_tubes.present?
  end

  def tubes_and_sources
    return [] unless transfers_to_tubes?

    tube_hash = generate_tube_hash
    # Sort the source well list in column order
    tube_hash.transform_values! do |well_list|
      well_list.sort_by { |well_name| WellHelpers.index_of(well_name) }
    end
    # Sort the tubes in column order based on their first well
    tube_hash.sort_by { |_tube, well_list| WellHelpers.index_of(well_list.first) }
  end

  def tagged?
    first_filled_well = wells.detect { |w| w.aliquots.first }
    first_filled_well && first_filled_well.aliquots.first.tag.identifier.present?
  end

  private

  def generate_tube_hash
    if transfer_request_collections.present?
      updated_tube_hash
    else
      legacy_tube_hash
    end
  end

  # Supports early plates. Uses plate_to_tube_transfers
  def legacy_tube_hash
    tube_hash = Hash.new { |h, i| h[i] = [] }
    # Build a list of all source wells for a given tube

    well_to_tube_transfers = transfers_to_tubes.reduce([]) do |all_transfers, transfer|
      all_transfers.concat(transfer.transfers.to_a)
    end

    well_to_tube_transfers.each do |well, tube|
      tube_hash[tube] << well
    end

    tube_hash
  end

  def updated_tube_hash
    tube_hash = Hash.new { |h, i| h[i] = [] }
    tube_index = {}

    transfer_requests = []
    tube_indexes = {}

    transfer_request_collections.each do |trc|
      transfer_requests.concat(trc.transfer_requests.all)
      tube_indexes.merge!(trc.target_tubes.index_by(&:uuid))
    end

    transfer_requests.each do |tr|
      location = well_uuids_to_location.fetch(tr.source_asset.uuid)
      tube = tube_indexes[tr.target_asset.uuid]
      tube_hash[ tube ] << location if tube
    end

    tube_hash
  end

  def well_uuids_to_location
    @well_uuids_to_map_description ||= wells.each_with_object({}) do |well, hash|
      hash[well.uuid] = well.location
    end
  end
end
