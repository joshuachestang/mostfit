class ProjectedReport < Report
  attr_accessor :from_date, :to_date, :branch, :center, :branch_id, :center_id

  def initialize(params, dates)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today + 1
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today + 7
    
    @name   = "Projected cash flow from #{@from_date} to #{@to_date}"
    @branch = if params and params[:branch_id] and not params[:branch_id].blank?
                Branch.all(:id => params[:branch_id])
              else
                Branch.all(:order => [:name])
              end    
    @center = Center.get(params[:center_id]) if params and params[:center_id] and not params[:center_id].blank?
 end
  
  def name
    "Projected cash flow from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Cash projection report"
  end
  
  def generate
    branches, centers, groups = {}, {}, {}
    histories = LoanHistory.sum_outstanding_by_group(self.from_date, self.to_date)
    @branch.each{|b|
      groups[b.id]||= {}
      branches[b.id] = b
      
      b.centers.each{|c|
        next if @center and @center.id!=c.id
        groups[b.id][c.id]||= {}
        centers[c.id]  = c
        c.client_groups.each{|g|
          #0              1              2              3                 4                 5,                  6                    7      
          #amount_applied,outstanding(p),outstanding(i),outstanding(fee),Outstanding(total),principal(scheduled),interest(scheudled),fee(scheduled)
          groups[b.id][c.id][g.id] = [0, 0, 0, 0, 0, 0, 0, g.name]
          history  = histories.find{|x| x.client_group_id==g.id and x.center_id==c.id} if histories
          if history
            principal_scheduled = history.scheduled_outstanding_principal.to_i
            total_scheduled     = history.scheduled_outstanding_total.to_i

            principal_actual = history.actual_outstanding_principal.to_i
            total_actual     = history.actual_outstanding_total.to_i            
          else
            principal_scheduled, total_scheduled, principal_actual, total_actual = 0, 0, 0, 0
          end

          groups[b.id][c.id][g.id][1] += principal_actual - principal_scheduled
          groups[b.id][c.id][g.id][2] += (total_actual - total_scheduled) - (principal_actual - principal_scheduled)
          groups[b.id][c.id][g.id][3] += total_actual - total_scheduled

          groups[b.id][c.id][g.id][4] += principal_scheduled
          groups[b.id][c.id][g.id][5] += total_scheduled - principal_scheduled
          groups[b.id][c.id][g.id][6] += total_scheduled

        }
      }
    }
    #1: Applied on
    Loan.all(:applied_on.gte => from_date, :applied_on.lte => to_date).each{|l|
      client    = l.client
      center_id = client.center_id
      next if not centers.key?(center_id)
      branch_id = centers[center_id].branch_id

      groups[branch_id][center_id][l.client.client_group_id][0] += l.amount
    }
    return [groups, centers, branches]
  end
end
