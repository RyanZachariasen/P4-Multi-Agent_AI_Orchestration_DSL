## Type Checking (6 rules)

### Environments

```
Γ : name → typ                         (variables)
Σ : name → (typ list × typ × bool)     (functions: params, return, needs_resource)
Δ : name → (name × typ) list           (type decls: field lists)
R : name set                            (declared resources)
```

### Rules

**1. Literals:**
Γ(x) = T
──────────────────────
Γ ⊢ EVar(x) : T

──────────────────────
Γ ⊢ EString(s) : TText

──────────────────────
Γ ⊢ EInt(n) : TInt

──────────────────────
Γ ⊢ EBool(b) : TBool

──────────────────────
Γ ⊢ EFloat(f) : TFloat

**2. Call with resource:**

```
Σ(f) = ([T₁,...,Tₙ], Ret, true)    Γ ⊢ eᵢ : Tᵢ    r ∈ R
──────────────────────────────────────────────────────────────
Γ ⊢ f(e₁,...,eₙ) on r : Ret
```

**3. Call without resource (builtin):**

```
Σ(f) = ([T₁,...,Tₙ], Ret, false)    Γ ⊢ eᵢ : Tᵢ
─────────────────────────────────────────────────────
Γ ⊢ f(e₁,...,eₙ) : Ret
```

**4. Field access:**

```
Γ ⊢ e : TNamed(S)    (f, T) ∈ Δ(S)
─────────────────────────────────────
Γ ⊢ e.f : T
```

**5. Statements:**
_Sekvenser af statements:_     ----- change to workflow

```
Γ ⊢ s_i ⇒ Γ_i    Γ' ⊢ s_i+1 ⇒ Γ_i+1       dom Γ <= dom Γ' <= dom Γ''  for i belongs to [0, n-1]
───────────────────────────────────────
Γ ⊢ (s_i ; s_i+1) ⇒ Γ_i+1
```

_5.1.: SLet_

```
Γ ⊢ e : T
──────────────────
Γ ⊢ (let x = e) ⇒ Γ[x ↦ T]
```

_5.2.: SPrint_

```
Γ ⊢ e : T
──────────────────
Γ ⊢ SPrint(e) ⇒ Γ
```

_5.3.: SWrite_

```
Γ ⊢ e_1 : TText    Γ ⊢ e_2 : TText
────────────────────────────────────
Γ ⊢ SWrite(e_1, e_2) ⇒ Γ
```

**6. BinOp:**

```
Γ ⊢ e_1 : TInt    Γ ⊢ e_2 : TInt   op ∈ {Add, Sub, Mul, Div}
──────────────────────────────────────────────────────────
Γ ⊢ e_1 op e_2 : TInt
```

```
Γ ⊢ e_1 : TFloat    Γ ⊢ e_2 : TFloat   op ∈ {Add, Sub, Mul, Div}
────────────────────────────────────────────────────────────
Γ ⊢ e_1 op e_2 : TFloat
```

```
Γ ⊢ e_1 : TFloat    Γ ⊢ e_2 : TInt    op ∈ {Add, Sub, Mul, Div}
────────────────────────────────────────────────────────────
Γ ⊢ e_1 op e_2 : TFloat
```

```
Γ ⊢ e_1 : TText Γ ⊢ e_2 : TText
────────────────────────────────────
Γ ⊢ e_1 Concat e_2 : TText
```

**7. Template validation (well-formedness):**

```
{(x,T)∣(x,T) ∈ fn.params} = {(y,U)∣(y,U) ∈ π_2​(fn.prompt)}​
​───────────────────────────────────────────────────────
⊢ DFunc(fn):ok
```

**8. Subtyping:**

```
─────────────
Code <: Text
```

```
Γ ⊢ e : T    T <: U
────────────────────
Γ ⊢ e : U
```

---