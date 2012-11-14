require 'rubygems'
require 'mail'
require 'httparty'
require 'xmlsimple'
require 'cgi'
require_relative 'sgerror'

class Sg


  URL_PREFIX = 'https://sendgrid.com/apiv2/'

  MAX_USERNAME_LEN  = 64
  MIN_PASSWORD_LEN  = 6
  MAX_EMAIL_LEN     = 64
  MAX_FIRSTNAME_LEN = 50
  MAX_LASTNAME_LEN  = 50
  MAX_ADDRESS_LEN   = 100
  MAX_CITY_LEN      = 100
  MAX_STATE_LEN     = 100
  MAX_ZIP_LEN       = 50
  MAX_COUNTRY_LEN   = 100
  MAX_PHONE_LEN     = 50
  MAX_WEBSITE_LEN   = 255
  MAX_COMPANY_LEN   = 255




  def initialize(api_user, api_key)
    @api_user =  api_user;
    @api_key = api_key;
  end



# Returns a confirmation message.
  def customer_add(params)

    params =
      add_missing_params(
        params,
        :username,
        :password,
        :confirm_password,
        :email,
        :first_name,
        :last_name,
        :address,
        :city,
        :state,
        :zip,
        :country,
        :phone,
        :website,
        :company)

    validate_params(params);

    response = call_sendgrid('customer.add', @api_user, @api_key, params);
  end



# Returns an array of Hashes, each of which desribes a single customer.
  def customer_profile(params)
    # Remove any parameters whose value is nil.
    params.delete_if {|key, value| value == nil}

    # Add the "task" parameter, with its mandated value.
    params[:task]=  "get";

    response = call_sendgrid('customer.profile', @api_user, @api_key, params);
  end



# Returns a confirmation message.
  def customer_enable(params)

    validate_params(params);

    response = call_sendgrid('customer.enable', @api_user, @api_key, params);
  end



  def add_missing_params(params, *required_param_keys)
    required_param_keys.each do |required_param_key|
      if (params.has_key?(required_param_key) == false) then
        params[required_param_key] = 'default'
      end
    end

    return params
  end



  def validate_params(params)
    params.each { |name, value|
      case name
        when :user
          validate_max_length(name, value, MAX_USERNAME_LEN);
        when :username
          validate_max_length(name, value, MAX_USERNAME_LEN);
        when :password
          validate_min_length(name, value, MIN_PASSWORD_LEN);
        when :confirm_password
          validate_min_length(name, value, MIN_PASSWORD_LEN);
          validate_match(name, value, :password, params[:password]);
        when :email
          validate_max_length(name, value, MAX_EMAIL_LEN);
          validate_email_format(name, value);
        when :first_name
          validate_max_length(name, value, MAX_FIRSTNAME_LEN);
        when :last_name
          validate_max_length(name, value, MAX_LASTNAME_LEN);
        when :address
          validate_max_length(name, value, MAX_ADDRESS_LEN);
        when :city
          validate_max_length(name, value, MAX_CITY_LEN);
        when :state
          validate_max_length(name, value, MAX_STATE_LEN);
        when :zip
          validate_max_length(name, value, MAX_ZIP_LEN);
        when :country
          validate_max_length(name, value, MAX_COUNTRY_LEN);
        when :phone
          validate_max_length(name, value, MAX_PHONE_LEN);
        when :website
          validate_max_length(name, value, MAX_WEBSITE_LEN);
        when :company
          validate_max_length(name, value, MAX_COMPANY_LEN);
        when :mail_domain
          # no validation
        else
          raise ArgumentError,
            "The SendGrid argument '#{name}' could not be validated." +
            " Please add a validation clause to the" +
            " 'validate_params()' method."
      end
    }

  end



  def validate_max_length(name, value, max_len)
    if (name.length > max_len)
      raise ArgumentError,
        "The SendGrid argument '#{name}' must be no longer than" +
        " #{max_len} characters. The supplied value '#{value}' is" +
        " #{value.length} characters long."
    end
  end



  def validate_min_length(name, value, min_len)
    if (name.length < min_len)
      raise ArgumentError,
        "The SendGrid argument '#{name}' must be no shorter than" +
          " #{min_len} characters. The supplied value '${value}' is" +
          " only #{value.length} characters long."
    end
  end



  def validate_match(name, value, other_name, other_value)
    if !(value == other_value)
      raise ArgumentError,
        "The SendGrid argument '#{name}', whose value is '#{value}'" +
        " must match the argument '#{other_name}', whose value is" +
        " '#{other_value}'."
    end
  end



  def validate_email_format(name, value)
    if (valid_email(value) == false)
      raise ArgumentError,
        "The SendGrid argument '#{name}', whose value is '#{value}'," +
        " must be a valid email address."
    end
  end



  def call_sendgrid(command, api_user, api_key, params)
    url = build_url(command, api_user, api_key, params);

    response = HTTParty.get(url);
    puts("DEBUG: response.code=#{response.code}");

    case response.code
      when 200
        get_messages(response)
      end
  end



# Returns an array of strings
  def get_messages(response)

    puts("DEBUG: response=#{response}");
    if (response.has_key?('result') && (response['result']['message'] == 'error'))
      # Either a single error message, or an array of error messages
      raise SGerror, response['result']['errors']['error'];
    elsif (response.has_key?('error'))
      raise SGerror, response['error']['message'], response['error']['code'];
    elsif (response.has_key?('users'))
      # A list of users
      response['users']['user']
    else
      # A success message.
      response['result']['message']
    end

  end



  def build_url(command, api_user, api_key, params)
    url = "#{URL_PREFIX}#{command}.xml?" +
          "api_user=#{api_user}&api_key=#{api_key}"

    puts("DEBUG: url=#{url}");
    puts("DEBUG: params=#{params}");
    params.each {|key, value| url << "&#{key}=#{CGI.escape(value)}" }

    return url
  end



# # This method is copied from:
# # http://stackoverflow.com/questions/9306329/regular-expression-for-email-in-ruby
  def valid_email( value )
    begin
      return false if value == ''
      parsed = Mail::Address.new( value )
      return parsed.address == value && parsed.local != parsed.address
     rescue Mail::Field::ParseError
       return false
     end
   end



    def display_response(response)
      begin
        response.each{|customer| puts(""); display_customer(customer)}
      end
    end



    def display_customer(customer)
      begin
        customer.each{|key, value| puts("#{key}: #{value}")}
      end
    end
end
