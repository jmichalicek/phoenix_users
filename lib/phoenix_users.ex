defmodule PhoenixUsers do
  @moduledoc """
  Documentation for PhoenixUsers.
  """

  @doc """
  Get the user model 

  ## Examples

      iex> PhoenixUsers.get_user_model
      {:ok, :user}

  """
  def get_user_model(bitstring) when is_bitstring(bitstring),  do: {:ok, Module.concat(String.split(bitstring, "."))}
  def get_user_model(atom) when is_atom(atom), do: {:ok, atom}
  def get_user_model(user_model), do: {:error, user_model}
  def get_user_model(), do: get_user_model(Application.get_env(:phoenix_users, :user_model))

  @doc """
  Check the user model for list of required fields as atoms and return it
  """
  def get_required_fields(user_model) do
    # prompt for any required data which is not already passed in
    # TODO: is it possible to detecth required fields from the schema rather than
    # making the developer specify them on the model?
    try do
      user_model.required_fields
    rescue
      UndefinedFunctionError ->
        []
    end
  end
end
