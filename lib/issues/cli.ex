defmodule Issues.CLI do
  @default_count 4
  @moduledoc """
  Handle the command line parsing and dispatch to
  the variaous funcs
  """
  def main(argv) do
    argv
    |> parse_args
    |> process
  end

  @doc """
  `argv` can be -h or --help , which returns help.
  Otherwise it is a github user name, project name and (optionally)
  the number of entries to format.
  Return a tuple of `{usr, project, count}`, or: `help` if help was given.
  """
  def parse_args(argv) do
    OptionParser.parse(
      argv,
      switches: [help: :boolean],
      aliases: [h: :help]
    )
    |> elem(1)
    |> args_to_internal_representation
  end
  def args_to_internal_representation([user, project, count]) do
    {user, project, String.to_integer(count)}
  end
  def args_to_internal_representation([user, project]) do
    {user, project, @default_count}
  end
  def args_to_internal_representation(_) do
    :help
  end

  def process(:help) do
    IO.puts """
    usage: issues <user> <project> [count | #{@default_count}]
    """
    System.halt(0)
  end
  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
    |> decode_response
    |> sort_into_decending_order
    |> last(count)
    |> print(["number", "created_at", "title"])

  end
  def decode_response({:ok, body}), do: body
  def decode_response({:error, error}) do
    IO.puts "Error fetching from Github: #{error["message"]}"
    System.halt(2)
  end

  def sort_into_decending_order(list_of_issues) do
    list_of_issues
    |> Enum.sort(
      fn i1, i2 -> i1["created_at"] >= i2["created_at"] end
    )
  end

  def last(list, count) do
    list |> Enum.take(count) |> Enum.reverse
  end

  def print(rows, headers) do
    headers |> Enum.join("\t") |> IO.puts
    rows |> Enum.map(fn row -> print_row(row, headers) end)
  end

  def print_row(row, headers) do
    headers
    |> Enum.map(fn header -> row[header] end)
    |> Enum.join("\t")
    |> IO.puts
  end

  def printable(str) when is_binary(str), do: str
  def printable(str), do: to_string(str)
end
