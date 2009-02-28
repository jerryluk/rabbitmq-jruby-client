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
  include_class('com.rabbitmq.client.MessageProperties')
  include_class('java.lang.String') { |package, name| "J#{name}" }
  
  class RabbitMQClientError < StandardError;end
  
  class QueueConsumer < DefaultConsumer
    def initialize(channel, block)
      @channel = channel
      @block = block
      super(channel)
    end
    
    def handleDelivery(consumer_tag, envelope, properties, body)
      delivery_tag = envelope.get_delivery_tag
      message_body = Marshal.load(String.from_java_bytes(body))
      # TODO: Do we need to do something with properties?
      @block.call message_body
      @channel.basic_ack(delivery_tag, false)
    end
  end
  
  class Queue
    def initialize(name, channel, durable=false)
      @name = name
      @durable = durable
      @channel = channel
      @channel.queue_declare(name, durable)
      self
    end
    
    def bind(exchange, routing_key='')
      @routing_key = routing_key
      @exchange = exchange
      raise RabbitMQClientError, "queue and exchange has different durable property" unless @durable == exchange.durable
      @channel.queue_bind(@name, @exchange.name, @routing_key)
      self
    end
    
    # Set props for different type of message. Currently they are:
    # RabbitMQClient::MessageProperties::MINIMAL_BASIC
    # RabbitMQClient::MessageProperties::MINIMAL_PERSISTENT_BASIC
    # RabbitMQClient::MessageProperties::BASIC
    # RabbitMQClient::MessageProperties::PERSISTENT_BASIC
    # RabbitMQClient::MessageProperties::TEXT_PLAIN
    # RabbitMQClient::MessageProperties::PERSISTENT_TEXT_PLAIN
    def publish(message_body, props=nil)
      auto_bind
      message_body_byte = Marshal.dump(message_body).to_java_bytes
      @channel.basic_publish(@exchange.name, @routing_key, props, message_body_byte)
      message_body
    end
    
    def persistent_publish(message_body, props=MessageProperties::PERSISTENT_BASIC)
      raise RabbitMQClientError, "can only publish persistent message to durable queue" unless @durable
      publish(message_body, props)
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
        exchange = Exchange.new("#{@name}_exchange", 'fanout', @channel, @durable)
        self.bind(exchange)
      end
    end
  end
  
  class Exchange
    attr_reader :name
    attr_reader :durable
    
    def initialize(name, type, channel, durable=false)
      @name = name
      @type = type
      @durable = durable
      @channel = channel
      @channel.exchange_declare(@name, type.to_s, durable)
      self
    end
  end
  
  # Class Methods
  class << self
  end
  
  attr_reader :channel
  attr_reader :connection
  
  # Instance Methods
  def initialize(options={:auto_connect => true})
    # server address
    @host = options[:host] || '127.0.0.1'
    @port = options[:port] || 5672
    
    # login details
    @username = options[:username] || 'guest'
    @password = options[:password] || 'guest'
    @vhost = options[:vhost] || '/'
    
    # queues and exchanges
    @queues = {}
    @exchanges = {}
    
    connect if options[:auto_connect]
    # Disconnect before the object is destroyed
    define_finalizer(self, lambda {|id| self.disconnect if self.connected? })
    self
  end
  
  def connect
    params = ConnectionParameters.new
    params.set_username(@username)
    params.set_password(@password)
    params.set_virtual_host(@vhost)
    params.set_requested_heartbeat(0)
    conn_factory = ConnectionFactory.new(params)
    @connection = conn_factory.new_connection(@host, @port)
    @channel = @connection.create_channel
  end
  
  def disconnect
    @channel.close
    @connection.close
    @connection = nil
  end
  
  def connected?
    @connection != nil
  end
  
  def queue(name, durable=false)
    @queues[name] ||= Queue.new(name, @channel, durable)
  end
  
  def exchange(name, type='fanout', durable=false)
    @exchanges[name] ||= Exchange.new(name, type, @channel, durable)
  end
end

