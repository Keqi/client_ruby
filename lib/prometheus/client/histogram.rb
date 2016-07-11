# encoding: UTF-8

require 'prometheus/client/metric'

module Prometheus
  module Client
    # A histogram samples observations (usually things like request durations 
    # or response sizes) and counts them in configurable buckets. It also 
    # provides a sum of all observed values.
    class Histogram < Metric

      # Value represents the state of a Histogram at a given point.
      class Value < Hash
        attr_accessor :sum, :total

        def initialize(buckets)
          @sum = 0.0
          @total = 0

          buckets.each do |bucket|
            self[bucket] = 0
          end
        end

        def observe(value)
          @sum += value
          @total += 1

          each do |bucket, count|
            self[bucket] += 1 if value <= bucket
          end
        end
      end

      # Offer a way to manually specify buckets
      def initialize(name, docstring, base_labels = {}, buckets = [])
        @buckets = buckets
        super(name, docstring, base_labels)
      end

      def type
        :histogram
      end

      def add(labels, value)
        fail ArgumentError, 'Label with name "le" is not permitted' if labels[:le]

        label_set = label_set_for(labels)
        synchronize { @values[label_set].observe(value) }
      end

      private

      def default
        Value.new(@buckets)
      end
    end
  end
end
