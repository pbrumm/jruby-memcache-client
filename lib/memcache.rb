
if RUBY_PLATFORM =~ /java/i
  require 'java'
  require File.dirname(__FILE__) + '/java/spy_memcached-2.5-3.jar'
end
require 'base64'



class MemCache
  if RUBY_PLATFORM =~ /java/i
    include_class 'net.spy.memcached.MemcachedClient'
    include_class 'net.spy.memcached.ConnectionFactory'
    include_class 'net.spy.memcached.KetamaConnectionFactory'
    include_class 'net.spy.memcached.AddrUtil'
    include_class 'java.util.List'
    include_class 'java.util.Arrays'
  end

  VERSION = '1.7.1'

  ##
  # Default options for the cache object.

  DEFAULT_OPTIONS = {
    :namespace   => nil,
    :readonly    => false,
    :multithread => true,
    :pool_initial_size => 10,
    :pool_min_size => 5,
    :pool_max_size => 100,
    :pool_max_idle => (1000 * 60 * 5),
    :pool_max_busy => (1000 * 30),
    :pool_maintenance_thread_sleep => (1000 * 30),
    :pool_socket_timeout => (1000 * 3),
    :pool_socket_connect_timeout => (1000 * 3),
    :pool_use_alive => false,
    :pool_use_failover => true,
    :pool_use_failback => true,
    :pool_use_nagle => false,
    :pool_name => 'default',
    :log_level => 2
  }

  ## CHARSET for Marshalling
  MARSHALLING_CHARSET = 'UTF-8'

  ##
  # Default memcached port.

  DEFAULT_PORT = 11211

  ##
  # Default memcached server weight.

  DEFAULT_WEIGHT = 1

  attr_accessor :request_timeout

  ##
  # The namespace for this instance

  attr_reader :namespace

  ##
  # The multithread setting for this instance

  attr_reader :multithread

  ##
  # The configured socket pool name for this client.
  attr_reader :pool_name

  ##
  # Configures the client
  def initialize(*args)
    @servers = []
    opts = {}

    case args.length
    when 0 then # NOP
    when 1 then
      arg = args.shift
      case arg
      when Hash   then opts = arg
      when Array  then @servers = arg
      when String then @servers = [arg]
      else raise ArgumentError, 'first argument must be Array, Hash or String'
      end
    when 2 then
      @servers, opts = args
      @servers = [@servers].flatten
    else
      raise ArgumentError, "wrong number of arguments (#{args.length} for 2)"
    end

    opts = DEFAULT_OPTIONS.merge opts

    @namespace = opts[:namespace] || opts["namespace"]
    @pool_name = opts[:pool_name] || opts["pool_name"]
    @readonly = opts[:readonly] || opts["readonly"]

    @client = MemcachedClient.new(KetamaConnectionFactory.new, AddrUtil.getAddresses(@servers.join(" ").to_java_string) )

   # @client.primitiveAsString = true
   # @client.sanitizeKeys = false
    
  #  weights = Array.new(@servers.size, DEFAULT_WEIGHT)

#    @pool = SockIOPool.getInstance(@pool_name)
#    unless @pool.initialized?
#      @pool.servers = @servers.to_java(:string)
#      @pool.weights = weights.to_java(:Integer)
#
#      @pool.initConn = opts[:pool_initial_size]
#      @pool.minConn = opts[:pool_min_size]
#      @pool.maxConn = opts[:pool_max_size]
#
#      @pool.maxIdle = opts[:pool_max_idle]
#      @pool.maxBusyTime = opts[:pool_max_busy]
#      @pool.maintSleep = opts[:pool_maintenance_thread_sleep]
#      @pool.socketTO = opts[:pool_socket_timeout]
#      @pool.socketConnectTO = opts[:pool_socket_connect_timeout]
#
#      @pool.failover = opts[:pool_use_failover]
#      @pool.failback = opts[:pool_use_failback]
#      @pool.aliveCheck = opts[:pool_use_alive]
#      @pool.nagle = opts[:pool_use_nagle]
#
#      # __method methods have been removed in jruby 1.5
#	  @pool.java_send :initialize rescue @pool.initialize__method
#    end
#
#    Logger.getLogger('com.meetup.memcached.MemcachedClient').setLevel(opts[:log_level])
#    Logger.getLogger('com.meetup.memcached.SockIOPool').setLevel(opts[:log_level])
  end

  def reset
    @client.shutdown
	  @client = MemcachedClient.new(KetamaConnectionFactory.new, AddrUtil.getAddresses(@servers.join(" ").to_java_string) )
  end
  def shutdown
    @client.shutdown
  end
  ##
  # Returns the servers that the client has been configured to
  # use. Injects an alive? method into the string so it works with the
  # updated Rails MemCacheStore session store class.
  def servers
    []
  end

  ##
  # Determines whether any of the connections to the servers is
  # alive. We are alive if it is the case.
  def alive?
    true
  end

  alias :active? :alive?

  ##
  # Retrieves a value associated with the key from the
  # cache. Retrieves the raw value if the raw parameter is set.
  def get(key, raw = false)
    value = @client.get(make_cache_key(key))

    value
  end

  alias :[] :get

  ##
  # Retrieves the values associated with the keys parameter.
  def get_multi(keys, raw = false)
    keys = keys.map {|k| make_cache_key(k)}
    keys = keys.to_java :String
    keys_collection = Arrays.asList(keys)

    values = {}
    values_map = @client.getBulk(keys_collection)
    
    values_map.keySet.to_a.each {|key|
      values = values_map.get(key).to_s
    }
    values
  end

  ##
  # Associates a value with a key in the cache. MemCached will expire
  # the value if an expiration is provided. The raw parameter allows
  # us to store a value without marshalling it first.
  def set(key, value, expiry = 0)
    
    value = value.to_java_string if value.kind_of?(String)
    key = make_cache_key(key)
    if expiry == 0
      @client.set key, expiry, value
    else
      @client.set key, expiry, value
    end
  end

  alias :[]= :set

  ##
  # Add a new value to the cache following the same conventions that
  # are used in the set method.
  def add(key, value, expiry = 0, raw = false)
    raise MemCacheError, "Update of readonly cache" if @readonly
    value = marshal_value(value) unless raw
    if expiry == 0
      @client.add make_cache_key(key), value
    else
      @client.add make_cache_key(key), value, expiration(expiry)
    end
  end

  ##
  # Removes the value associated with the key from the cache. This
  # will ignore values that are not already present in the cache,
  # which makes this safe to use without first checking for the
  # existance of the key in the cache first.
  def delete(key, expires = 0)
    raise MemCacheError, "Update of readonly cache" if @readonly
    @client.delete(make_cache_key(key))
  end

  ##
  # Replaces the value associated with a key in the cache if it
  # already is stored. It will not add the value to the cache if it
  # isn't already present.
  def replace(key, value, expiry = 0, raw = false)
    raise MemCacheError, "Update of readonly cache" if @readonly
    value = marshal_value(value) unless raw
    if expiry == 0
      @client.replace make_cache_key(key), value
    else
      @client.replace make_cache_key(key), value
    end
  end

  ##
  # Increments the value associated with the key by a certain amount.
  def incr(key, amount = 1)
    raise MemCacheError, "Update of readonly cache" if @readonly
    value = get(key) || 0
    value += amount
    set key, value
    value
  end

  ##
  # Decrements the value associated with the key by a certain amount.
  def decr(key, amount = 1)
    raise MemCacheError, "Update of readonly cache" if @readonly
    value = get(key) || 0
    value -= amount
    set key, value
    value
  end

  ##
  # Clears the cache.
  def flush_all
    @client.flush_all
  end

  ##
  # Reports statistics on the cache.
  def stats
    stats_hash = {}
    @client.stats.each do |server, stats|
      stats_hash[server] = Hash.new
      stats.each do |key, value|
        unless key == 'version'
          value = value.to_f
          value = value.to_i if value == value.ceil
        end
        stats_hash[server][key] = value
      end
    end
    stats_hash
  end

  class MemCacheError < RuntimeError; end

  protected
  def make_cache_key(key)
    if namespace.nil? then
      key.to_java_string
    else
      "#{@namespace}:#{key}".to_java_string
    end
  end

  def expiration(expiry)
    java.util.Date.new((Time.now.to_i + expiry) * 1000)
  end

  def marshal_value(value)
    encoded = Base64.encode64(Marshal.dump(value))
    marshal_bytes = encoded.to_java_bytes
    java.lang.String.new(marshal_bytes, MARSHALLING_CHARSET)
  end
end

