require 'rabbitmq/rabbitmq_client'
require 'workling/clients/base'

module Workling
  module Clients
    class WorklingRabbitMQClient < Workling::Clients::Base
      def connect
        @client = RabbitMQClient.new
      end
      
      def close
        @client.disconnect if @client.connected?
      end
      
      def request(queue, value)
        @client.queue(queue).publish(value)
      end
      
      def retrieve(queue)
        @client.queue(queue).retrieve
      end
      
      def subscribe(queue)
        @client.queue(queue).subscribe do |value|
          yield value
        end
      end
    end
  end
end