import Foundation

struct Vocabulary {
    static let aiML: [String: String] = [
        "\\bllama\\b": "LLaMA",
        "\\bgpt[\\s-]?4\\b": "GPT-4",
        "\\bgpt[\\s-]?4o\\b": "GPT-4o",
        "\\bgpt[\\s-]?3\\.?5\\b": "GPT-3.5",
        "\\bdall[\\s-]?e\\b": "DALL-E",
        "\\bmid[\\s-]?journey\\b": "Midjourney",
        "\\bdeep[\\s-]?seek\\b": "DeepSeek",
        "\\bpie[\\s-]?torch\\b": "PyTorch",
        "\\btensor[\\s-]?flow\\b": "TensorFlow",
        "\\bscikit[\\s-]learn\\b": "scikit-learn",
        "\\bpsychic[\\s-]?learn\\b": "scikit-learn",
        "\\bskit[\\s-]?learn\\b": "scikit-learn",
        "\\bhugging[\\s-]?face\\b": "Hugging Face",
        "\\bonyx\\b": "ONNX",
        "\\bonnx\\b": "ONNX",
        "\\bcore[\\s-]?ml\\b": "CoreML",
        "\\boh[\\s-]?llama\\b": "Ollama",
        "\\bollama\\b": "Ollama",
        "\\blang[\\s-]?chain\\b": "LangChain",
        "\\bllama[\\s-]?index\\b": "LlamaIndex",
        "\\bv[\\s-]?llm\\b": "vLLM",
        "\\blora\\b": "LoRA",
        "\\blaura\\b": "LoRA",
        "\\bq[\\s-]?lora\\b": "QLoRA",
        "\\bq[\\s-]?laura\\b": "QLoRA",
        "\\b(?:rag)\\b": "RAG",
        "\\brlhf\\b": "RLHF",
        "\\bpeft\\b": "PEFT",
        "\\bgptq\\b": "GPTQ",
        "\\bgguf\\b": "GGUF",
        "\\brelu\\b": "ReLU",
        "\\bgelu\\b": "GeLU",
        "\\blstm\\b": "LSTM",
        "\\bwee[\\s-]?v(?:ee[\\s-]?)?(?:ate|eight|8)\\b": "Weaviate",
        "\\bweaviate\\b": "Weaviate",
        "\\bqdrant\\b": "Qdrant",
        "\\bchroma[\\s-]?db\\b": "ChromaDB",
        "\\bfaiss\\b": "FAISS",
        "\\bpg[\\s-]?vector\\b": "pgvector",
        "\\bpine[\\s-]?cone\\b": "Pinecone",
    ]

    static let web: [String: String] = [
        "\\bnext[\\s-]?js\\b": "Next.js",
        "\\bvue[\\s-]?js\\b": "Vue.js",
        "\\bsvelte[\\s-]?kit\\b": "SvelteKit",
        "\\bnuxt[\\s-]?js\\b": "Nuxt.js",
        "\\bsolid[\\s-]?js\\b": "Solid.js",
        "\\bnode[\\s-]?js\\b": "Node.js",
        "\\bexpress[\\s-]?js\\b": "Express.js",
        "\\btype[\\s-]?script\\b": "TypeScript",
        "\\bjava[\\s-]?script\\b": "JavaScript",
        "\\bveet\\b": "Vite",
        "\\bweb[\\s-]?pack\\b": "webpack",
        "\\bes[\\s-]?build\\b": "esbuild",
        "\\bes[\\s-]?lint\\b": "ESLint",
        "\\bt[\\s-]?rpc\\b": "tRPC",
        "\\btailwind(?:\\s+css)?\\b": "Tailwind CSS",
        "\\bpost[\\s-]?css\\b": "PostCSS",
        "\\bcss[\\s-]?in[\\s-]?js\\b": "CSS-in-JS",
        "\\bshadow[\\s-]?cn\\b": "shadcn",
        "\\bshad[\\s-]?cn\\b": "shadcn",
        "\\bchakra[\\s-]?ui\\b": "Chakra UI",
        "\\bmaterial[\\s-]?ui\\b": "Material UI",
        "\\bflex[\\s-]?box\\b": "flexbox",
        "\\bcss[\\s-]?grid\\b": "CSS Grid",
        "\\bz[\\s-]?index\\b": "z-index",
        "\\bhtml[\\s-]?5\\b": "HTML5",
        "\\baria\\b": "ARIA",
        "\\bw[\\s-]?c[\\s-]?a[\\s-]?g\\b": "WCAG",
        "\\bwee[\\s-]?cag\\b": "WCAG",
        "\\bwai[\\s-]?aria\\b": "WAI-ARIA",
        "\\brest[\\s-]?api\\b": "REST API",
        "\\bgraph[\\s-]?(?:ql|q[\\s-]?l|cool)\\b": "GraphQL",
        "\\bweb[\\s-]?socket(?:s)?\\b": "WebSocket",
        "\\bg[\\s-]?r[\\s-]?p[\\s-]?c\\b": "gRPC",
        "\\bo[\\s-]?auth(?:\\s*2(?:\\.0)?)?\\b": "OAuth 2.0",
        "\\boh[\\s-]?auth\\b": "OAuth",
        "\\bj[\\s-]?w[\\s-]?t\\b": "JWT",
        "\\bcors\\b": "CORS",
        "\\bsea[\\s-]?surf\\b": "CSRF",
        "\\bc[\\s-]?s[\\s-]?r[\\s-]?f\\b": "CSRF",
        "\\bhttp[\\s-]?2\\b": "HTTP/2",
        "\\bhttp[\\s-]?3\\b": "HTTP/3",
        "\\bssr\\b": "SSR",
        "\\bssg\\b": "SSG",
    ]

    static let database: [String: String] = [
        "\\bpost[\\s-]?gres(?:[\\s-]?sql)?\\b": "PostgreSQL",
        "\\bpostgresql\\b": "PostgreSQL",
        "\\bmy[\\s-]?(?:sequel|sql)\\b": "MySQL",
        "\\bsqlite\\b": "SQLite",
        "\\bsequel[\\s-]?lite\\b": "SQLite",
        "\\bmongo[\\s-]?db\\b": "MongoDB",
        "\\bredis\\b": "Redis",
        "\\breed[\\s-]?iss?\\b": "Redis",
        "\\bdynamo[\\s-]?db\\b": "DynamoDB",
        "\\bcockroach[\\s-]?db\\b": "CockroachDB",
        "\\bsuper[\\s-]?base\\b": "Supabase",
        "\\bsupabase\\b": "Supabase",
        "\\bfire[\\s-]?base\\b": "Firebase",
        "\\bfire[\\s-]?store\\b": "Firestore",
        "\\belastic[\\s-]?search\\b": "Elasticsearch",
        "\\bclick[\\s-]?house\\b": "ClickHouse",
        "\\bneo[\\s-]?4[\\s-]?j\\b": "Neo4j",
        "\\bmaria[\\s-]?db\\b": "MariaDB",
        "\\bsql[\\s-]?alchemy\\b": "SQLAlchemy",
    ]

    static let devops: [String: String] = [
        "\\bkubernetes\\b": "Kubernetes",
        "\\bcube[\\s-]?(?:control|ctl|c[\\s-]?t[\\s-]?l)\\b": "kubectl",
        "\\bkubectl\\b": "kubectl",
        "\\bk[\\s-]?8[\\s-]?s\\b": "k8s",
        "\\bk[\\s-]?3[\\s-]?s\\b": "k3s",
        "\\bmini[\\s-]?kube\\b": "minikube",
        "\\bengine[\\s-]?x\\b": "nginx",
        "\\bnginx\\b": "nginx",
        "\\bn[\\s-]?jinx\\b": "nginx",
        "\\btraefik\\b": "Traefik",
        "\\bg[\\s-]?unicorn\\b": "Gunicorn",
        "\\bgunicorn\\b": "Gunicorn",
        "\\bu[\\s-]?v[\\s-]?corn\\b": "Uvicorn",
        "\\buvicorn\\b": "Uvicorn",
        "\\bc[\\s-]?i[\\s-]?/?c[\\s-]?d\\b": "CI/CD",
        "\\bgit[\\s-]?hub(?:\\s+actions)?\\b": "GitHub",
        "\\bgit[\\s-]?lab\\b": "GitLab",
        "\\bver[\\s-]?(?:sell?|sal)\\b": "Vercel",
        "\\bvercel\\b": "Vercel",
        "\\bcloud[\\s-]?flare\\b": "Cloudflare",
        "\\bcloud[\\s-]?front\\b": "CloudFront",
        "\\broute[\\s-]?53\\b": "Route 53",
        "\\bcloud[\\s-]?formation\\b": "CloudFormation",
        "\\bterraform\\b": "Terraform",
        "\\bsue[\\s-]?d(?:oo|oh)\\b": "sudo",
        "\\bdaymon\\b": "daemon",
        "\\bcidr\\b": "CIDR",
        "\\bhome[\\s-]?brew\\b": "Homebrew",
        "\\bz[\\s-]?sh\\b": "Zsh",
        "\\bneo[\\s-]?vim\\b": "Neovim",
        "\\bvs[\\s-]?code\\b": "VS Code",
    ]

    static let python: [String: String] = [
        "\\bnum[\\s-]?pie\\b": "NumPy",
        "\\bnumb[\\s-]?pie\\b": "NumPy",
        "\\bnumpy\\b": "NumPy",
        "\\bsigh[\\s-]?pie\\b": "SciPy",
        "\\bscipy\\b": "SciPy",
        "\\bmat[\\s-]?plot[\\s-]?lib\\b": "Matplotlib",
        "\\bmatplotlib\\b": "Matplotlib",
        "\\bjupyter\\b": "Jupyter",
        "\\bfast[\\s-]?api\\b": "FastAPI",
        "\\bdjango\\b": "Django",
        "\\bjango\\b": "Django",
        "\\bpydantic\\b": "Pydantic",
        "\\bpy[\\s-]?test\\b": "pytest",
        "\\basync[\\s-]?io\\b": "asyncio",
    ]

    static var all: [String: String] {
        var merged: [String: String] = [:]
        merged.merge(aiML) { _, new in new }
        merged.merge(web) { _, new in new }
        merged.merge(database) { _, new in new }
        merged.merge(devops) { _, new in new }
        merged.merge(python) { _, new in new }
        return merged
    }

    static func loadUserPromptTerms() -> String? {
        let url = AppConstants.promptTermsFile
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }

        var lines: [String] = []
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            lines.append(trimmed)
        }
        guard !lines.isEmpty else { return nil }
        return lines.joined(separator: ", ")
    }

    static func buildInitialPrompt() -> String? {
        let basePrompt = InitialPrompt.forLanguage(Settings.shared.language)
        let userTerms = loadUserPromptTerms()
        if let userTerms {
            return "\(basePrompt), \(userTerms)"
        }
        return basePrompt
    }

    static func createPromptTermsTemplate() {
        let url = AppConstants.promptTermsFile
        guard !FileManager.default.fileExists(atPath: url.path) else { return }

        AppConstants.ensureDataDir()

        let template = """
        # Auris — Custom Prompt Terms
        #
        # Add words/phrases here that Whisper should recognise.
        # These prime the speech model to expect these terms,
        # making it more likely to transcribe them correctly.
        #
        # One term per line, or comma-separated.
        # Lines starting with # are comments.
        #
        # Examples:
        # Allsopp
        # Web Directions
        # Conffab, Respond, Scroll
        #
        # Changes take effect on next transcription.

        """
        try? template.write(to: url, atomically: true, encoding: .utf8)
    }
}
