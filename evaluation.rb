class Evaluation
  attr_accessor :type, :value, :score, :state, :reason

  TYPE = {
    siren: "siren",
    vat: "vat",
  }
  STATE = {
    unconfirmed: "unconfirmed",
    favorable: "favorable",
    unfavorable: "unfavorable",
  }
  COMPANY_STATE = {
    active: "actif",
  }
  REASON = {
    ongoing_database_update: "ongoing_database_update",
    unable_to_reach_api: "unable_to_reach_api",
    company_opened: "company_opened",
    company_closed: "company_closed",
  }

  def initialize(type:, value:, score:, state:, reason:)
    @type = type
    @value = value
    @score = score
    @state = state
    @reason = reason
  end

  def to_s
    "#{@type}, #{@value}, #{@score}, #{@state}, #{@reason}"
  end
end