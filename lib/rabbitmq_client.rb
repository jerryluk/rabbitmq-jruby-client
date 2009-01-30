require 'java'
require File.dirname(__FILE__) + '/junit.jar'
require File.dirname(__FILE__) + '/commons-cli-1.1.jar'
require File.dirname(__FILE__) + '/commons-io-1.2.jar'
require File.dirname(__FILE__) + '/rabbitmq-client.jar'

class RabbitMQClient
  include ObjectSpace
  include_class('com.rabbitmq.client.Connection')
  include_class('com.rabbitmq.client.ConnectionParameters')
  include_class('com.rabbitmq.client.ConnectionFactory')
  include_class('com.rabbitmq.client.Channel')
  include_class('com.rabbitmq.client.Consumer')
  include_class('com.rabbitmq.client.DefaultConsumer')
  include_class('java.lang.String') { |package, name| "J#{name}" }
  
  class QueueConsumer < DefaultConsumer
    def initialize(channel, block)
      @channel = channel
      @block = block
      super(channel)
    end
    
    def handleDelivery(consumer_tag, envelope, properties, body)
      delivery_tag = envelope.get_delivery_tag
      message_body = Marshal.load(String.from_java_bytes(body))
      @block.call message_body
      @channel.basic_ack(delivery_tag, false)
    end
  end
  
  class Queue
    def initialize(name, channel)
      @name = name
      @channel = channel
      @channel.queue_declare(name)
      self
    end
    
    def bind(exchange, routing_key=nil)
      @routing_key = routing_key || "#{@name}_#{Time.new.to_i.to_s}_#{rand(100).to_s}"
      @exchange = exchange
      @channel.queue_bind(@name, @exchange.name, @routing_key)
      self
    end
    
    def publish(message_body, props=nil)
      auto_bind
      message_body_byte = Marshal.dump(message_body).to_java_bytes
      @channel.basic_publish(@exchange.name, @routing_key, props, message_body_byte)
      message_body
    end
    
    def retrieve
      auto_bind
      message_body = nil
      no_ack = false
      response = @channel.basic_get(@name, no_ack)
      if response
        props = response.get_props
        message_body = Marshal.load(String.from_java_bytes(response.get_body))
        delivery_tag = response.get_envelope.get_delivery_tag
        @channel.basic_ack(delivery_tag, false)
      end
      message_body
    end
    
    def subscribe(&block)
      no_ack = false
      @channel.basic_consume(@name, no_ack, QueueConsumer.new(@channel, block))
    end
    
    protected
    def auto_bind
      unless @exchange
        exchange = Exchange.new("@name_exchange", 'fanout', @channel)
        self.bind(exchange)
      end
    end
  end
  
  class Exchange
    attr_reader :name
    
    def initialize(name, type, channel)
      @name = name
      @type = type
      @channel = channel
      @channel.exchange_declare(@name, type.to_s)
      self
    end
  end
  
  # Class Methods
  class << self
  end
  
  attr_reader :channel
  attr_reader :connection
  
  # Instance Methods
  def initialize(options={})
    # server address
    host = options[:host] || '127.0.0.1'
    port = options[:port] || 5672
    
    # login details
    username = options[:username] || 'guest'
    password = options[:password] || 'guest'
    vhost = options[:vhost] || '/'
    
    # queues and exchanges
    @queues = {}
    @exchanges = {}
    
    params = ConnectionParameters.new
    params.set_username(username)
    params.set_password(password)
    params.set_virtual_host(vhost)
    params.set_requested_heartbeat(0)
    conn_factory = ConnectionFactory.new(params)
    @connection = conn_factory.new_connection(host, port)
    @channel = @connection.create_channel
    # Disconnect before the object is destroyed
    define_finalizer(self, lambda {|id| self.disconnect})
    self
  end
  
  def disconnect
    @channel.close
    @connection.close
    @connection = nil
  end
  
  def connected?
    @connection != nil
  end
  
  def queue(name)
    @queues[name] ||= Queue.new(name, @channel)
  end
  
  def exchange(name, type='fanout')
    @exchanges[name] ||= Exchange.new(name, type, @channel)
  end
end

