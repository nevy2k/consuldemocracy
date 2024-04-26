class Proposal::Exporter
  require "csv"
  include JsonExporter

  def initialize(proposals)
    #raise proposals.inspect
    @proposals = proposals
  end

  def to_csv
    CSV.generate(headers: true) do |csv|
      csv << headers
      @proposals.each { |proposals| csv << csv_values(proposals) }
    end
  end

  def model
    Proposal
  end

  private

    def headers
      [
        'Azonosító',
        'Cím',
        'Összes szavazat',
        'Helyszín',
        'Kezdeti dátum',
        'Befejezési dátum',
        'Összefoglaló',
        'Leírás',
      ]
    end

    def csv_values(proposal)
      [
        proposal.id.to_s,
        proposal.title,
        proposal.total_votes.to_s,
        proposal.location,
        proposal.starts_at.strftime('%d/%m/%Y-%H:%M'),
        proposal.ends_at&.strftime('%d/%m/%Y-%H:%M'),
        proposal.summary,
        proposal.description
      ]
    end

    def json_values(proposal)
      {
        id: proposal.id,
        title: proposal.title,
        summary: strip_tags(proposal.summary),
        description: strip_tags(proposal.description)
      }
    end
end
