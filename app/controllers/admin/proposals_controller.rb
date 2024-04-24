class Admin::ProposalsController < Admin::BaseController
  include HasOrders
  include CommentableActions
  include FeatureFlags
  feature_flag :proposals

  has_orders %w[created_at]

  before_action :load_proposal, except: :index

  def show
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
