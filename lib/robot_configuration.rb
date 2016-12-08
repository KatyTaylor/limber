# frozen_string_literal: true
##
module RobotConfiguration
  BedOrCar = Struct.new(:barcode, :name)

  class Register
    def self.configure(&block)
      register = new
      register.instance_eval(&block)
      register.configuration
    end

    def custom_robot(key, hash)
      @robots[key] = hash
    end

    def bravo_robot(target_state = 'passed', &block)
      simple_robot('bravo', target_state, &block)
    end

    def simple_robot(type, target_state = 'passed', &block)
      added_robot = RobotConfiguration::Simple.new(type, target_state, &block)
      @robots[added_robot.key] = added_robot.configuration
      added_robot
    end

    def initialize
      @robots = {}
    end

    def configuration
      @robots
    end
  end

  class Simple
    attr_reader :source_purpose, :target_purpose, :layout, :type, :target_state, :source_bed_state, :target_bed_state

    def initialize(type, target_state = 'passed', &block)
      @layout = 'bed'
      @type = type
      @target_state = target_state
      instance_eval(&block) if block
    end

    def bed(number)
      barcode = SBCF::SangerBarcode.new(prefix: 'BD', number: number)
      ean13 = barcode.machine_barcode.to_s
      BedOrCar.new(ean13, "Bed #{number}")
    end

    def car(position)
      number = position.tr(',').to_i
      barcode = SBCF::SangerBarcode.new(prefix: 'BD', number: number)
      ean13 = barcode.machine_barcode.to_s
      BedOrCar.new(ean13, "Carousel #{position}")
    end

    def from(source_purpose, bed, state = 'passed')
      @source_purpose = source_purpose
      @source_bed = bed
      @source_bed_state = state
    end

    def source_bed_name
      @source_bed.name
    end

    def source_bed_barcode
      @source_bed.barcode
    end

    def to(target_purpose, bed, state = 'pending')
      @target_purpose = target_purpose
      @target_bed = bed
      @target_bed_state = state
    end

    def target_bed_name
      @target_bed.name
    end

    def target_bed_barcode
      @target_bed.barcode
    end

    def name
      "#{type} #{source_purpose} => #{target_purpose}"
    end

    def key
      "#{type} #{source_purpose} to #{target_purpose}".parameterize
    end

    def configuration
      {
        name: name,
        layout: layout,
        beds: {
          source_bed_barcode  => { purpose: source_purpose, states: [source_bed_state],  label: source_bed_name },
          target_bed_barcode  => { purpose: target_purpose, states: [target_bed_state],  label: target_bed_name, parent: source_bed_barcode, target_state: target_state }
        }
      }
    end
  end
end
