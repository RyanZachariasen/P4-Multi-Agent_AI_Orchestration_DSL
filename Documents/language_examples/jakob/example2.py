from python import Int

claude = Anthropic(
    api_key=os.environ.get("ANTHROPIC_API_KEY"),
)

def calculate(text):
    response: str = claude.messages.create(
        max_tokens=10000,
        system = "You are a calculator, which can returns a single number in the format x=y, where x is the variable im going to look for with the parser and y is the response im looking for . You will be given a prompt and you should only provide the answer to the problem.",
        messages=text,
        model="claude-sonnet-4-6",
    ).content[0].text

    idx = response.index("x=")
    j = 2
    int_string = ""
    while idx+j<len(response) and (response[idx+j] != " " or response[idx+j] != "\n"):
        int_string += response[idx+j]
        j += 1
    
    return int(int_string)
            
    
if __name__ == "__main__":
    print(calculate(sys.argv[1]))