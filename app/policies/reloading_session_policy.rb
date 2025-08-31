# frozen_string_literal: true

class ReloadingSessionPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    owner?
  end

  def create?
    true
  end

  def new?
    create?
  end

  def update?
    owner?
  end

  def edit?
    update?
  end

  def destroy?
    owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(account: account_user.account)
    end
  end

  private

  def owner?
    record.account_id == account_user.account_id
  end
end
