module ExternalData

  class Exception < StandardError

    attr_accessor :title, :origin, :msg

    def initialize(title, msg)
      self.title = title
      self.msg = msg

      super(
        title:,
        msg:
      )
    end

  end

end
