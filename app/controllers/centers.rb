class Centers < Application
  before :get_context
  provides :xml, :yaml, :js

  def index
    @centers = @branch.centers
    display @centers
  end

  def show(id)
    @center = Center.get(id)
    raise NotFound unless @center
    @clients = @center.clients
    display [@center, @clients], 'clients/index'
  end

  def new
    only_provides :html
    @center = Center.new
    display @center
  end

  def create(center)
    @center = Center.new(center)
    @center.branch = @branch  # set direct context
    if @center.save
      redirect resource(@branch, :centers), :message => {:notice => "Center '#{@center.name}' was successfully created"}
    else
#       message[:error] = "Center failed to be created"
      render :new  # error messages will be shown
    end
  end

  def edit(id)
    only_provides :html
    @center = Center.get(id)
    raise NotFound unless @center
    display @center
  end

  def update(id, center)
    @center = Center.get(id)
    raise NotFound unless @center
    if @center.update_attributes(center)
       redirect resource(@branch, :centers), :message => {:notice => "Center '#{@center.name}' has been edited"}
    else
      display @center, :edit  # error messages will be shown
    end
  end

  def delete(id)
    edit(id)  # so far these are the same
  end

  def destroy(id)
    @center = Center.get(id)
    raise NotFound unless @center
    if @center.destroy
      redirect resource(@branch, :centers), :message => {:notice => "Center '#{@center.name}' has been deleted"}
    else
      raise InternalServerError
    end
  end

  private
  def get_context
    @branch = Branch.get(params[:branch_id])
    raise NotFound unless @branch
  end
end # Centers