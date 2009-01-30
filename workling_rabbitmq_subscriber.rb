require 'workling/remote/invokers/base'

#
#  A basic polling invoker. 
#  
module Workling
  module Remote
    module Invokers
      class WorklingRabbitMQSubscriber < Workling::Remote::Invokers::Base
        cattr_accessor :sleep_time
        # 
        #  set up client, sleep time
        #
        def initialize(routing, client_class)
          super
          WorklingRabbitMQSubscriber.sleep_time = Workling.config[:sleep_time] || 0.2
        end
        
        #
        #  Starts main Invoker Loop. The invoker runs until stop() is called. 
        #
        def listen
          connect do
            routes.each do |queue|
              @client.subscribe(queue) do |args|
                run(queue, args)
              end
            end
          end
          while (!Thread.current[:shutdown]) do
            sleep(self.class.sleep_time)
          end
        end
        
        #
        #  Gracefully stops the Invoker. The currently executing Jobs should be allowed
        #  to finish. 
        #
        def stop
          Thread.current[:shutdown] = true
        end
      end
    end
  end
end
Workling::Remote.invoker = Workling::Remote::Invokers::WorklingRabbitMQSubscriber