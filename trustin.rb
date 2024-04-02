require "json"
require "net/http"
require_relative "evaluation"

class TrustIn < Evaluation

  def initialize(evaluations)
    @evaluations = evaluations
  end

  def update_score
    @evaluations.each do |evaluation|
      case evaluation.type.downcase
        when TYPE[:siren]
          evaluation_siren(evaluation)
        when TYPE[:vat]
          evaluation_vat(evaluation)
        else
          raise Exception.new "Evaluation type '" + evaluation.type + "' not supported yet." # TODO : notify, bug tracker, report policy
      end
    end
  end

  def evaluation_siren(evaluation)
    if evaluation.score == 0 || (evaluation.state == STATE[:unconfirmed] && evaluation.reason == REASON[:ongoing_database_update])
      uri = URI("https://xxxpublic.opendatasoft.com/api/records/1.0/search/?dataset=economicref-france-sirene-v3xxx" \
                  "&q=#{evaluation.value}&sort=datederniertraitementetablissement" \
                  "&refine.etablissementsiege=oui")
      response = Net::HTTP.get(uri)
      unless response.kind_of? Net::HTTPSuccess
        response = File.read("siren-example-output.json")
      end
      parsed_response = JSON.parse(response)
      company_state = parsed_response["records"].first["fields"]["etatadministratifetablissement"]
      if company_state == COMPANY_STATE[:active]
        evaluation.state = STATE[:favorable]
        evaluation.reason = REASON[:company_opened]
        evaluation.score = 100
      else
        evaluation.state = STATE[:unfavorable]
        evaluation.reason = REASON[:company_closed]
        evaluation.score = 100
      end
    elsif evaluation.state == STATE[:unconfirmed] && evaluation.reason == REASON[:unable_to_reach_api]
      if evaluation.score >= 50
        evaluation.score -= 5
      elsif evaluation.score >= 1
        evaluation.score -= 1
      end
    elsif evaluation.state == STATE[:favorable]
      evaluation.score -= 1
    end
  end

  def evaluation_vat(evaluation)
    if evaluation.score == 0 || (evaluation.state == STATE[:unconfirmed] && evaluation.reason == REASON[:ongoing_database_update])
      parsed_response = [
        { state: "favorable", reason: "company_opened" },
        { state: "unfavorable", reason: "company_closed" },
        { state: "unconfirmed", reason: "unable_to_reach_api" },
        { state: "unconfirmed", reason: "ongoing_database_update" },
      ].sample
      evaluation.state = parsed_response[:state]
      evaluation.reason = parsed_response[:reason]
      evaluation.score = 100
    elsif evaluation.state == STATE[:unconfirmed] && evaluation.reason == REASON[:unable_to_reach_api]
      if evaluation.score >= 50
        evaluation.score -= 1
      elsif evaluation.score >= 3
        evaluation.score -= 3
      end
    elsif evaluation.state == STATE[:favorable]
      evaluation.score -= 1
    end
  end

end
