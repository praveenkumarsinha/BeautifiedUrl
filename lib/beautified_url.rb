module BeautifiedUrl

  def self.included(base)
    base.extend(ClassMethods)
    base.send(:before_create, :beautify_url_on_create)
    base.send(:before_update, :beautify_url_on_update)
    base.send(:before_save, :beautify_url_on_save)
    base.send(:before_validation, :beautify_url_on_validate)
  end

  module ClassMethods
    attr_accessor :bu_token
    attr_accessor :bu_attributes_hset
    attr_accessor :bu_scope_set
    attr_accessor :bu_callback_event

    #Checks if model is well equipped to use beautified_url capability by checking up attribute names, if it is paired with attribute starting with name '_bu_'
    def is_beautifiable?
      @bu_token ||= "_bu_"
      @bu_attributes_hset = {}
      attribute_names.each do |attribute_name|
        if attribute_name.starts_with?(@bu_token)
          p_attr = attribute_name.gsub(@bu_token, "") #parent attribute name
          @bu_attributes_hset[p_attr] = attribute_name if attribute_names.include?(p_attr)
        end
      end
      (not @bu_attributes_hset.empty?)
    end

    #Accepts scope parameter for beautified_url
    #Eg => beautify_url_with_scope :company_id #For universal scope of all attributes with beautified_url capabilities.
    #Eg => beautify_url_with_scope {:name => :company_id, :title => :subdomain}
    def beautify_url_with_scope(options)
      options = options.to_s if options.is_a?(Symbol)
      @bu_scope_set = options if options.is_a?(Hash) or options.is_a?(String)
    end

    #Signifies on what 'before' event should the beautification take palce.
    #Valid values are :create (default value), :save, :update, :validate
    def beautify_on(event)
      begin
        event = event.to_sym unless event.is_a?(Symbol)
        @bu_callback_event = [:create, :save, :update, :validate].include?(event) ? event : :create
      rescue Exception => e
        Rails.logger.debug e.message
        Rails.logger.debug e.backtrace.join("\n")
        @bu_callback_event = :create
      end

      @bu_callback_event
    end
  end

  def attribute_scope_hash_set(base = self.class)
    scope_hset = base.bu_scope_set

    if base.bu_scope_set.is_a?(String) and base.attribute_names.include?(base.bu_scope_set)
      scope_hset = {}
      base.bu_attributes_hset.keys.each { |p_attr| scope_hset[p_attr] = base.bu_scope_set }
    end
    scope_hset ||{}
  end

  #generates condition array to be used while searching for unique record from bu_attribute value
  def conditions_array(p_attr, bu_attr, bu_attr_value, base = self.class)
    condition_array = ["#{bu_attr} = ? ", bu_attr_value]
    unless self.send(base.primary_key).nil?
      condition_array[0] = "#{condition_array[0]} and #{base.primary_key} != ?"
      condition_array.push(self.send(base.primary_key))
    end

    attribute_scope_hash_set.each do |sp_key, sp_key_scope|
      sp_key, sp_key_scope = sp_key.to_s, sp_key_scope.to_s
      if p_attr == sp_key and base.attribute_names.include?(sp_key) and base.attribute_names.include?(sp_key_scope)
        condition_array[0] = "#{condition_array[0]} and #{sp_key_scope} = ?"
        condition_array.push(self.send(sp_key_scope))
      end
    end
    condition_array
  end

  #finds uniqueness of bu_attribute's value (with scope if defined)
  def make_unique_beautiful_url(p_attr, bu_attr, bu_attr_value, base = self.class)
    bu_attr_value_t = bu_attr_value

    keep_looking_flag = true
    while (keep_looking_flag)
      if base.where(conditions_array(p_attr, bu_attr, bu_attr_value_t)).count == 0
        keep_looking_flag = false
      else
        counter ||= 0
        counter += 1
        bu_attr_value_t = "#{bu_attr_value}-#{counter}"
      end
    end

    bu_attr_value_t
  end

#makes beautiful url by looking at parent attribute(s) whose bu_attributes are identified by "_bu_" (default bu_token)
#only if bu_attribute is not already populated
  def beautify_url(base = self.class)
    return unless base.is_beautifiable?

    base.bu_attributes_hset.each do |p_attr, bu_attr|
      if self.send(bu_attr).nil?
        unless (p_attr.nil? or p_attr.empty?) #If parent attribute is not nil or empty
          self.send("#{bu_attr}=", make_unique_beautiful_url(p_attr, bu_attr, self.send(p_attr).beautify_me))
        end
      end
    end
  end

  private
  def beautify_url_on_create(base = self.class)
    beautify_url if base.bu_callback_event.nil? or base.bu_callback_event == :create
  end

  def beautify_url_on_update(base = self.class)
    beautify_url if base.bu_callback_event == :update
  end

  def beautify_url_on_save(base = self.class)
    beautify_url if base.bu_callback_event == :save
  end

  def beautify_url_on_validate(base = self.class)
    beautify_url if base.bu_callback_event == :validate
  end

end

class String
  def beautify_me
    self.downcase.gsub(/[ -]+/, "-").gsub(/[^a-zA-Z0-9-]/, "")
  end
end


#Adding to ActiveRecord::Base
ActiveRecord::Base.send(:include, BeautifiedUrl)