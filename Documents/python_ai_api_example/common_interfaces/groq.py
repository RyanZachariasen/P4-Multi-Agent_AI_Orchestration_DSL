import os

from groq import Groq

client = Groq(
    api_key=os.environ.get("GROQ_API_KEY"),
)

chat_completion = client.chat.completions.create(
    messages=[
        {
            "role": "user",
            "content": "Hello, i am prompt",
        }
    ],
    model="llama-3.3-70b-versatile",
)

print(chat_completion.choices[0].message.content)


"""
EVERY PARAMETER FOR THE "CREATE" METHOD USED ABOVE:
        self,
        *,
        messages: Iterable[ChatCompletionMessageParam],
        model: str,
        citation_options: Optional[Literal["enabled", "disabled"]] | Omit = omit,
        compound_custom: Optional[completion_create_params.CompoundCustom] | Omit = omit,
        disable_tool_validation: Optional[bool] | Omit = omit,
        documents: Optional[Iterable[completion_create_params.Document]] | Omit = omit,
        exclude_domains: Optional[SequenceNotStr[str]] | Omit = omit,
        frequency_penalty: Optional[float] | Omit = omit,
        function_call: Optional[completion_create_params.FunctionCall] | Omit = omit,
        functions: Optional[Iterable[completion_create_params.Function]] | Omit = omit,
        include_domains: Optional[SequenceNotStr[str]] | Omit = omit,
        include_reasoning: Optional[bool] | Omit = omit,
        logit_bias: Optional[Dict[str, int]] | Omit = omit,
        logprobs: Optional[bool] | Omit = omit,
        max_completion_tokens: Optional[int] | Omit = omit,
        max_tokens: Optional[int] | Omit = omit,
        metadata: Optional[Dict[str, str]] | Omit = omit,
        n: Optional[int] | Omit = omit,
        parallel_tool_calls: Optional[bool] | Omit = omit,
        presence_penalty: Optional[float] | Omit = omit,
        reasoning_effort: Optional[Literal["none", "default", "low", "medium", "high"]] | Omit = omit,
        reasoning_format: Optional[Literal["hidden", "raw", "parsed"]] | Omit = omit,
        response_format: Optional[completion_create_params.ResponseFormat] | Omit = omit,
        search_settings: Optional[completion_create_params.SearchSettings] | Omit = omit,
        seed: Optional[int] | Omit = omit,
        service_tier: Optional[Literal["auto", "on_demand", "flex", "performance"]] | Omit = omit,
        stop: Union[Optional[str], SequenceNotStr[str], None] | Omit = omit,
        store: Optional[bool] | Omit = omit,
        stream: Optional[Literal[False]] | Omit = omit,
        temperature: Optional[float] | Omit = omit,
        tool_choice: Optional[ChatCompletionToolChoiceOptionParam] | Omit = omit,
        tools: Optional[Iterable[ChatCompletionToolParam]] | Omit = omit,
        top_logprobs: Optional[int] | Omit = omit,
        top_p: Optional[float] | Omit = omit,
        user: Optional[str] | Omit = omit,
        # Use the following arguments if you need to pass additional parameters to the API that aren't available via kwargs.
        # The extra values given here take precedence over values defined on the client or passed to this method.
        extra_headers: Headers | None = None,
        extra_query: Query | None = None,
        extra_body: Body | None = None,
        timeout: float | httpx.Timeout | None | NotGiven = not_given,
    ) -> ChatCompletion: ...
"""