defmodule PhoenixUsers.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use PhoenixUsers.Web, :controller
      use PhoenixUsers.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  @doc """
  Used along with the __using__ macro similar to Phoenix's App.Web macro
  to allow `use PhoenixUsers.Web, :controller` to act as if `use App.Web, :controller`
  had been used.
  """
  def controller do
    # figure out the app and call its App.Web.controller()
    # and then use this as `use PhoenixUsers, :controller
    # I bet this trick can be used to let the code do `use PhoenixUsers, :user`
    # and `use PhoenixUsers, :repo` to have access to an aliased `User` and `Repo`
    {module, []} = Keyword.get(Mix.Project.get().application(), :mod)
    module = Module.concat(module, :Web)
    apply(module, :controller, [])
  end

  def view do
    {module, []} = Keyword.get(Mix.Project.get().application(), :mod)
    module = Module.concat(module, :Web)
    apply(module, :view, [])
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

end
