class PaymentObserver
  include DataMapper::Observer
  
  observe Payment

  # This function will make entries to the transaction database when save, update or delete event is triggered
  def self.make_transaction_entry(payment, action)

    client_name = payment.client ? payment.client.name : nil
    center = payment.client && payment.client.center ? payment.client.center : nil
    center_id = center ? center.id : nil
    center_name = center ? center.name : nil
    
    staff_member = payment.received_by_staff_id ? StaffMember.get(payment.received_by_staff_id) : nil
    staff_member_name = staff_member ? staff_member.name : nil
    fee_name = payment.fee ? payment.fee.name : nil
    
    extended_info = payment.extended_info
    
    transaction = TransactionLog.create(
                                        :txn_guid => payment.guid,
                                        :parent_org_guid => payment.parent_org_guid,
                                        :parent_domain_guid => payment.parent_domain_guid,
                                        :update_type => action,
                                        :txn_type => :receipt,
                                        :nature_of_transaction => "#{payment.type}_received".to_sym,
                                        :sub_type_id => payment.fee_id,
                                        :sub_type_name => fee_name,
                                        :amount => payment.amount,
                                        :currency => :INR,
                                        :effective_date => payment.received_on,
                                        :record_date => payment.created_at,
                                        :updated_at_time => nil,
                                        :verified_at_time => nil,
                                        :deleted_at_time => nil,
                                        :paid_by_type => :client,
                                        :paid_by_id => payment.client_id,
                                        :paid_by_name => client_name,
                                        :received_by_type => :staff_member,
                                        :received_by_id => payment.received_by_staff_id,
                                        :received_by_name => staff_member_name,
                                        :transacted_at_type => :center,
                                        :transacted_at_id => center_id,
                                        :transacted_at_name => center_name,
                                        :extended_info_items => extended_info  
                                        )
  end

  # We are only observing the create and update methods because the payment model only uses these methods. 
  # In case of of a payment getting deleted the update function is called and then the save function is called. 
  
  # In case of a payment getting updated (i.e. some of the details of the payment are changed and then saved) then the current payment is deleted and a new copy with the updated details is saved with a new payment id

  before :create do
    self.parent_org_guid = Organization.get_organization(self.received_on)
  end
  
  after :create do
    return false unless Mfi.first.transaction_logging_enabled
    PaymentObserver.make_transaction_entry(self, :create)
  end

  after :update do
    return false unless Mfi.first.transaction_logging_enabled
    PaymentObserver.make_transaction_entry(self, :delete)
  end
  
  
end








