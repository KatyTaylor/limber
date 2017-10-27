# frozen_string_literal: true

module LabwareCreators::SupportParent
  module PlateReadyForCustomPoolingOnly
    def support_parent?(parent)
      parent.is_a?(Limber::Plate) && parent.tagged? && parent.ready_for_custom_pooling?
    end
  end
end
