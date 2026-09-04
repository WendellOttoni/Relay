defmodule Relay.Leads.Lead do
  @moduledoc "A validated commercial opportunity submitted by a visitor."

  @enforce_keys [:name, :email, :project_type, :summary]
  defstruct [:name, :email, :company, :project_type, :timeframe, :budget, :summary, :proposal]

  @type t :: %__MODULE__{
          name: String.t(),
          email: String.t(),
          company: String.t() | nil,
          project_type: String.t(),
          timeframe: String.t() | nil,
          budget: String.t() | nil,
          summary: String.t(),
          proposal: String.t() | nil
        }
end
