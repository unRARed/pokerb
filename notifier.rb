# A simple class for storing and displaying
# simple notifications in the UI
#
class Notifier
  attr_reader :is_read
  attr_accessor :message, :color

  def initialize(is_read: false, message: "", color: "orange")
    @is_read = is_read
    @color = color
  end

  def read
    @is_read = true
    @message
  end
end
