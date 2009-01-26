require 'rubygems'
require 'spec'
require File.dirname(__FILE__) + '/../lib/rabbitmq_client'

describe RabbitMQClient do
  before(:each) do
    @client = RabbitMQClient.new
  end
  
  it "should able to create a connection" do
    @client.connection.should_not be_nil
  end
  
  it "should able to create a channel" do
    @client.channel.should_not be_nil
  end
  
  it "should be able to create a new exchange" do
    exchange = @client.exchange('test_exchange', 'direct')
    exchange.should_not be_nil
  end
  
  describe Queue do
    before(:each) do
      @queue = @client.queue('test_queue')
      @exchange = @client.exchange('test_exchange', 'direct')
    end
    
    it "should able to create a queue" do
      @queue.should_not be_nil
    end
    
    it "should able to bind to an exchange" do
      @queue.bind(@exchange).should_not be_nil
    end
    
    it "should able to publish and retrieve a message" do
      @queue.bind(@exchange)
      @queue.publish('Hello World')
      @queue.retrieve.should == 'Hello World'
    end
    
    it "should able to subscribe with a callback function" do
      @queue.bind(@exchange)
      @queue.publish('2')
      t = @queue.subscribe do |v|
       v.should == "2"        
      end
      Thread.kill t
    end
  end
end