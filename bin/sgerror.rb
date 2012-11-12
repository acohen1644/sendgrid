class SGerror < StandardError
  attr_reader :messages

  def initialize(messages)
    super(messages)
    @messages = messages
  end
end
