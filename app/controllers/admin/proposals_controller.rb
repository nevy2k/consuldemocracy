class Admin::ProposalsController < Admin::BaseController
  include HasOrders
  include CommentableActions
  include FeatureFlags
  feature_flag :proposals

  has_orders %w[created_at]

  before_action :load_proposal, except: [:index,:publish_accepted_proposals,:download_csv]

  def show
  end

  def index
    if params[:sort_by] == 'asc'
      @proposals = (Proposal.all.sort_by { |proposal| proposal.total_votes })
    elsif params[:sort_by] == 'desc'
      @proposals = (Proposal.all.sort_by { |proposal| -proposal.total_votes })
    else
      @proposals = Proposal.all
    end
  end

  def download_csv
    if params[:sort_by] == 'asc'
      @proposals = (Proposal.all.sort_by { |proposal| proposal.total_votes })
    elsif params[:sort_by] == 'desc'
      @proposals = (Proposal.all.sort_by { |proposal| -proposal.total_votes })
    else
      @proposals = Proposal.all
    end
    respond_to do |format|
      format.html
      format.js
      format.csv do
        send_data Proposal::Exporter.new(@proposals).to_csv,
                  filename: "kezdemenyezesek.csv"
      end
    end
  end

  def publish_accepted_proposals
    proposal_ids = params[:proposal_ids]
    @proposals = Proposal.where(id: proposal_ids, status: 1)
    @proposals.each do |accepted_proposal|
      accepted_proposal.publish
    end
    redirect_to admin_proposals_path, notice: "Sikeresen publikáltad az elfogadott kezdeményezéseket"
  end

  def accept_proposal
    if @proposal.update(status: 1)
      redirect_to admin_proposals_path, notice: "Elfogadtad #{@proposal.title} kezdeményezést"
    else
      redirect_to admin_proposals_path, notice: "Sikertelen volt a kezdeményezés elfogadása"
    end
  end

  def decline_proposal
    if @proposal.update(status: 2)
      redirect_to admin_proposals_path, alert: "#{@proposal.title} kezdeményezés elutasítva"
    else
      redirect_to admin_proposals_path, notice: "Hiba történt #{@proposal.title} kezdeményezés elutasítása során"
    end
  end

  def update
    if @proposal.update(proposal_params)
      redirect_to admin_proposal_path(@proposal), notice: t("admin.proposals.update.notice")
    else
      render :show
    end
  end

  def toggle_selection
    @proposal.toggle :selected
    @proposal.save!
  end

  private

    def resource_model
      Proposal
    end

    def load_proposal
      @proposal = Proposal.find(params[:id] || params[:proposal_id])
    end

    def proposal_params
      params.require(:proposal).permit(allowed_params)
    end

    def allowed_params
      [:selected]
    end
end
