import Foundation

struct InitialPrompt {
    private static let prompts: [AppLanguage: String] = [
        .en: """
            The following is a clear, well-structured transcription. \
            We deploy to PostgreSQL, MySQL, MongoDB, Redis, and Elasticsearch. \
            The stack uses Kubernetes, Docker, nginx, Terraform, and CI/CD via GitHub. \
            Authentication uses OAuth, JWT, CORS, and CSRF protection. \
            The API layer uses GraphQL, gRPC, WebSocket, and REST API endpoints. \
            The frontend is built with JavaScript, TypeScript, React, Next.js, \
            Vue.js, Svelte, and Node.js, styled with Tailwind CSS and webpack. \
            We follow ARIA and WCAG accessibility standards in our HTML5 and CSS Grid layouts. \
            Machine learning uses PyTorch, TensorFlow, scikit-learn, NumPy, and SciPy. \
            We work with LLaMA, GPT-4, DALL-E, LoRA, RAG, RLHF, ONNX, CoreML, and MLX models \
            via Hugging Face, LangChain, FastAPI, Django, and Pydantic. \
            Deployment targets Vercel, Cloudflare, Supabase, Gunicorn, and Uvicorn. \
            We use Whisper, mlx-whisper, Auris, Claude, Anthropic, and OpenAI tools \
            on macOS, iOS, iPadOS with Xcode, Swift, SwiftUI on Apple Silicon.
            """,

        .ru: """
            Это ясная, хорошо структурированная транскрипция. \
            Мы деплоим на PostgreSQL, MySQL, MongoDB, Redis и Elasticsearch. \
            Стек использует Kubernetes, Docker, nginx, Terraform и CI/CD через GitHub. \
            Аутентификация использует OAuth, JWT, CORS и CSRF-защиту. \
            API-слой использует GraphQL, gRPC, WebSocket и REST API эндпоинты. \
            Фронтенд построен на JavaScript, TypeScript, React, Next.js, \
            Vue.js, Svelte и Node.js, стилизован с Tailwind CSS и webpack. \
            Мы следуем стандартам доступности ARIA и WCAG в HTML5 и CSS Grid макетах. \
            Машинное обучение использует PyTorch, TensorFlow, scikit-learn, NumPy и SciPy. \
            Мы работаем с моделями LLaMA, GPT-4, DALL-E, LoRA, RAG, RLHF, ONNX, CoreML и MLX \
            через Hugging Face, LangChain, FastAPI, Django и Pydantic. \
            Деплой идёт на Vercel, Cloudflare, Supabase, Gunicorn и Uvicorn. \
            Мы используем Whisper, mlx-whisper, Auris, Claude, Anthropic и OpenAI инструменты \
            на macOS, iOS, iPadOS с Xcode, Swift, SwiftUI на Apple Silicon.
            """,

        .de: """
            Dies ist eine klare, gut strukturierte Transkription. \
            Wir deployen auf PostgreSQL, MySQL, MongoDB, Redis und Elasticsearch. \
            Der Stack nutzt Kubernetes, Docker, nginx, Terraform und CI/CD über GitHub. \
            Authentifizierung nutzt OAuth, JWT, CORS und CSRF-Schutz. \
            Die API-Schicht nutzt GraphQL, gRPC, WebSocket und REST-API-Endpunkte. \
            Das Frontend ist mit JavaScript, TypeScript, React, Next.js, \
            Vue.js, Svelte und Node.js gebaut, gestylt mit Tailwind CSS und webpack. \
            Wir folgen ARIA- und WCAG-Barrierefreiheitsstandards in unseren HTML5- und CSS-Grid-Layouts. \
            Maschinelles Lernen nutzt PyTorch, TensorFlow, scikit-learn, NumPy und SciPy. \
            Wir arbeiten mit LLaMA, GPT-4, DALL-E, LoRA, RAG, RLHF, ONNX, CoreML- und MLX-Modellen \
            über Hugging Face, LangChain, FastAPI, Django und Pydantic. \
            Deployment auf Vercel, Cloudflare, Supabase, Gunicorn und Uvicorn. \
            Wir nutzen Whisper, mlx-whisper, Auris, Claude, Anthropic und OpenAI-Tools \
            auf macOS, iOS, iPadOS mit Xcode, Swift, SwiftUI auf Apple Silicon.
            """,

        .fr: """
            Voici une transcription claire et bien structurée. \
            Nous déployons sur PostgreSQL, MySQL, MongoDB, Redis et Elasticsearch. \
            La pile utilise Kubernetes, Docker, nginx, Terraform et CI/CD via GitHub. \
            L'authentification utilise OAuth, JWT, CORS et la protection CSRF. \
            La couche API utilise GraphQL, gRPC, WebSocket et les endpoints REST API. \
            Le frontend est construit avec JavaScript, TypeScript, React, Next.js, \
            Vue.js, Svelte et Node.js, stylisé avec Tailwind CSS et webpack. \
            Nous suivons les standards d'accessibilité ARIA et WCAG dans nos layouts HTML5 et CSS Grid. \
            L'apprentissage automatique utilise PyTorch, TensorFlow, scikit-learn, NumPy et SciPy. \
            Nous travaillons avec les modèles LLaMA, GPT-4, DALL-E, LoRA, RAG, RLHF, ONNX, CoreML et MLX \
            via Hugging Face, LangChain, FastAPI, Django et Pydantic. \
            Le déploiement cible Vercel, Cloudflare, Supabase, Gunicorn et Uvicorn. \
            Nous utilisons Whisper, mlx-whisper, Auris, Claude, Anthropic et les outils OpenAI \
            sur macOS, iOS, iPadOS avec Xcode, Swift, SwiftUI sur Apple Silicon.
            """,

        .es: """
            Esta es una transcripción clara y bien estructurada. \
            Desplegamos en PostgreSQL, MySQL, MongoDB, Redis y Elasticsearch. \
            El stack usa Kubernetes, Docker, nginx, Terraform y CI/CD a través de GitHub. \
            La autenticación usa OAuth, JWT, CORS y protección CSRF. \
            La capa de API usa GraphQL, gRPC, WebSocket y endpoints REST API. \
            El frontend está construido con JavaScript, TypeScript, React, Next.js, \
            Vue.js, Svelte y Node.js, estilizado con Tailwind CSS y webpack. \
            Seguimos los estándares de accesibilidad ARIA y WCAG en nuestros layouts HTML5 y CSS Grid. \
            El aprendizaje automático usa PyTorch, TensorFlow, scikit-learn, NumPy y SciPy. \
            Trabajamos con modelos LLaMA, GPT-4, DALL-E, LoRA, RAG, RLHF, ONNX, CoreML y MLX \
            vía Hugging Face, LangChain, FastAPI, Django y Pydantic. \
            El despliegue apunta a Vercel, Cloudflare, Supabase, Gunicorn y Uvicorn. \
            Usamos Whisper, mlx-whisper, Auris, Claude, Anthropic y herramientas de OpenAI \
            en macOS, iOS, iPadOS con Xcode, Swift, SwiftUI en Apple Silicon.
            """,

        .it: """
            Questa è una trascrizione chiara e ben strutturata. \
            Facciamo deploy su PostgreSQL, MySQL, MongoDB, Redis ed Elasticsearch. \
            Lo stack utilizza Kubernetes, Docker, nginx, Terraform e CI/CD tramite GitHub. \
            L'autenticazione usa OAuth, JWT, CORS e protezione CSRF. \
            Il livello API usa GraphQL, gRPC, WebSocket ed endpoint REST API. \
            Il frontend è costruito con JavaScript, TypeScript, React, Next.js, \
            Vue.js, Svelte e Node.js, stilizzato con Tailwind CSS e webpack. \
            Seguiamo gli standard di accessibilità ARIA e WCAG nei nostri layout HTML5 e CSS Grid. \
            L'apprendimento automatico usa PyTorch, TensorFlow, scikit-learn, NumPy e SciPy. \
            Lavoriamo con modelli LLaMA, GPT-4, DALL-E, LoRA, RAG, RLHF, ONNX, CoreML e MLX \
            tramite Hugging Face, LangChain, FastAPI, Django e Pydantic. \
            Il deploy è su Vercel, Cloudflare, Supabase, Gunicorn e Uvicorn. \
            Usiamo Whisper, mlx-whisper, Auris, Claude, Anthropic e strumenti OpenAI \
            su macOS, iOS, iPadOS con Xcode, Swift, SwiftUI su Apple Silicon.
            """,

        .pt: """
            Esta é uma transcrição clara e bem estruturada. \
            Fazemos deploy no PostgreSQL, MySQL, MongoDB, Redis e Elasticsearch. \
            O stack usa Kubernetes, Docker, nginx, Terraform e CI/CD via GitHub. \
            A autenticação usa OAuth, JWT, CORS e proteção CSRF. \
            A camada de API usa GraphQL, gRPC, WebSocket e endpoints REST API. \
            O frontend é construído com JavaScript, TypeScript, React, Next.js, \
            Vue.js, Svelte e Node.js, estilizado com Tailwind CSS e webpack. \
            Seguimos os padrões de acessibilidade ARIA e WCAG nos nossos layouts HTML5 e CSS Grid. \
            O aprendizado de máquina usa PyTorch, TensorFlow, scikit-learn, NumPy e SciPy. \
            Trabalhamos com modelos LLaMA, GPT-4, DALL-E, LoRA, RAG, RLHF, ONNX, CoreML e MLX \
            via Hugging Face, LangChain, FastAPI, Django e Pydantic. \
            O deploy visa Vercel, Cloudflare, Supabase, Gunicorn e Uvicorn. \
            Usamos Whisper, mlx-whisper, Auris, Claude, Anthropic e ferramentas OpenAI \
            no macOS, iOS, iPadOS com Xcode, Swift, SwiftUI no Apple Silicon.
            """,

        .nl: """
            Dit is een duidelijke, goed gestructureerde transcriptie. \
            We deployen naar PostgreSQL, MySQL, MongoDB, Redis en Elasticsearch. \
            De stack gebruikt Kubernetes, Docker, nginx, Terraform en CI/CD via GitHub. \
            Authenticatie gebruikt OAuth, JWT, CORS en CSRF-bescherming. \
            De API-laag gebruikt GraphQL, gRPC, WebSocket en REST API-eindpunten. \
            De frontend is gebouwd met JavaScript, TypeScript, React, Next.js, \
            Vue.js, Svelte en Node.js, gestyled met Tailwind CSS en webpack. \
            We volgen ARIA- en WCAG-toegankelijkheidsstandaarden in onze HTML5- en CSS Grid-lay-outs. \
            Machine learning gebruikt PyTorch, TensorFlow, scikit-learn, NumPy en SciPy. \
            We werken met LLaMA, GPT-4, DALL-E, LoRA, RAG, RLHF, ONNX, CoreML- en MLX-modellen \
            via Hugging Face, LangChain, FastAPI, Django en Pydantic. \
            Deployen op Vercel, Cloudflare, Supabase, Gunicorn en Uvicorn. \
            We gebruiken Whisper, mlx-whisper, Auris, Claude, Anthropic en OpenAI-tools \
            op macOS, iOS, iPadOS met Xcode, Swift, SwiftUI op Apple Silicon.
            """,

        .ja: """
            これは明確で構造化された文字起こしです。\
            PostgreSQL、MySQL、MongoDB、Redis、Elasticsearchにデプロイしています。\
            スタックはKubernetes、Docker、nginx、Terraform、GitHub経由のCI/CDを使用しています。\
            認証にはOAuth、JWT、CORS、CSRF保護を使用しています。\
            APIレイヤーはGraphQL、gRPC、WebSocket、REST APIエンドポイントを使用しています。\
            フロントエンドはJavaScript、TypeScript、React、Next.js、\
            Vue.js、Svelte、Node.jsで構築し、Tailwind CSSとwebpackでスタイリングしています。\
            HTML5とCSS GridレイアウトでARIAとWCAGアクセシビリティ基準に従っています。\
            機械学習はPyTorch、TensorFlow、scikit-learn、NumPy、SciPyを使用しています。\
            LLaMA、GPT-4、DALL-E、LoRA、RAG、RLHF、ONNX、CoreML、MLXモデルを\
            Hugging Face、LangChain、FastAPI、Django、Pydantic経由で扱っています。\
            デプロイ先はVercel、Cloudflare、Supabase、Gunicorn、Uvicornです。\
            Whisper、mlx-whisper、Auris、Claude、Anthropic、OpenAIツールを\
            macOS、iOS、iPadOSでXcode、Swift、SwiftUI、Apple Silicon上で使用しています。
            """,

        .ko: """
            이것은 명확하고 잘 구조화된 전사입니다. \
            PostgreSQL, MySQL, MongoDB, Redis, Elasticsearch에 배포합니다. \
            스택은 Kubernetes, Docker, nginx, Terraform과 GitHub를 통한 CI/CD를 사용합니다. \
            인증은 OAuth, JWT, CORS 및 CSRF 보호를 사용합니다. \
            API 레이어는 GraphQL, gRPC, WebSocket 및 REST API 엔드포인트를 사용합니다. \
            프론트엔드는 JavaScript, TypeScript, React, Next.js, \
            Vue.js, Svelte, Node.js로 구축되었고 Tailwind CSS와 webpack으로 스타일링됩니다. \
            HTML5와 CSS Grid 레이아웃에서 ARIA 및 WCAG 접근성 표준을 따릅니다. \
            머신러닝은 PyTorch, TensorFlow, scikit-learn, NumPy, SciPy를 사용합니다. \
            LLaMA, GPT-4, DALL-E, LoRA, RAG, RLHF, ONNX, CoreML, MLX 모델을 \
            Hugging Face, LangChain, FastAPI, Django, Pydantic을 통해 다룹니다. \
            배포 대상은 Vercel, Cloudflare, Supabase, Gunicorn, Uvicorn입니다. \
            Whisper, mlx-whisper, Auris, Claude, Anthropic, OpenAI 도구를 \
            macOS, iOS, iPadOS에서 Xcode, Swift, SwiftUI로 Apple Silicon에서 사용합니다.
            """,

        .zh: """
            这是一段清晰、结构良好的转录。\
            我们部署到 PostgreSQL、MySQL、MongoDB、Redis 和 Elasticsearch。\
            技术栈使用 Kubernetes、Docker、nginx、Terraform 和通过 GitHub 的 CI/CD。\
            认证使用 OAuth、JWT、CORS 和 CSRF 保护。\
            API 层使用 GraphQL、gRPC、WebSocket 和 REST API 端点。\
            前端使用 JavaScript、TypeScript、React、Next.js、\
            Vue.js、Svelte 和 Node.js 构建，使用 Tailwind CSS 和 webpack 样式。\
            我们在 HTML5 和 CSS Grid 布局中遵循 ARIA 和 WCAG 无障碍标准。\
            机器学习使用 PyTorch、TensorFlow、scikit-learn、NumPy 和 SciPy。\
            我们使用 LLaMA、GPT-4、DALL-E、LoRA、RAG、RLHF、ONNX、CoreML 和 MLX 模型，\
            通过 Hugging Face、LangChain、FastAPI、Django 和 Pydantic。\
            部署目标为 Vercel、Cloudflare、Supabase、Gunicorn 和 Uvicorn。\
            我们使用 Whisper、mlx-whisper、Auris、Claude、Anthropic 和 OpenAI 工具，\
            在 macOS、iOS、iPadOS 上使用 Xcode、Swift、SwiftUI 在 Apple Silicon 上运行。
            """,

        .ar: """
            هذا نسخ واضح ومنظم جيدًا. \
            ننشر على PostgreSQL و MySQL و MongoDB و Redis و Elasticsearch. \
            يستخدم المكدس Kubernetes و Docker و nginx و Terraform و CI/CD عبر GitHub. \
            يستخدم التوثيق OAuth و JWT و CORS وحماية CSRF. \
            تستخدم طبقة API نقاط نهاية GraphQL و gRPC و WebSocket و REST API. \
            الواجهة الأمامية مبنية بـ JavaScript و TypeScript و React و Next.js و \
            Vue.js و Svelte و Node.js، مصممة بـ Tailwind CSS و webpack. \
            نتبع معايير الوصول ARIA و WCAG في تخطيطات HTML5 و CSS Grid. \
            التعلم الآلي يستخدم PyTorch و TensorFlow و scikit-learn و NumPy و SciPy. \
            نعمل مع نماذج LLaMA و GPT-4 و DALL-E و LoRA و RAG و RLHF و ONNX و CoreML و MLX \
            عبر Hugging Face و LangChain و FastAPI و Django و Pydantic. \
            أهداف النشر هي Vercel و Cloudflare و Supabase و Gunicorn و Uvicorn. \
            نستخدم أدوات Whisper و mlx-whisper و Auris و Claude و Anthropic و OpenAI \
            على macOS و iOS و iPadOS مع Xcode و Swift و SwiftUI على Apple Silicon.
            """,

        .hi: """
            यह एक स्पष्ट, अच्छी तरह संरचित प्रतिलेखन है। \
            हम PostgreSQL, MySQL, MongoDB, Redis और Elasticsearch पर डिप्लॉय करते हैं। \
            स्टैक Kubernetes, Docker, nginx, Terraform और GitHub के माध्यम से CI/CD का उपयोग करता है। \
            प्रमाणीकरण OAuth, JWT, CORS और CSRF सुरक्षा का उपयोग करता है। \
            API परत GraphQL, gRPC, WebSocket और REST API एंडपॉइंट का उपयोग करती है। \
            फ्रंटएंड JavaScript, TypeScript, React, Next.js, \
            Vue.js, Svelte और Node.js से बनाया गया है, Tailwind CSS और webpack से स्टाइल किया गया है। \
            हम अपने HTML5 और CSS Grid लेआउट में ARIA और WCAG पहुंचनीयता मानकों का पालन करते हैं। \
            मशीन लर्निंग PyTorch, TensorFlow, scikit-learn, NumPy और SciPy का उपयोग करती है। \
            हम LLaMA, GPT-4, DALL-E, LoRA, RAG, RLHF, ONNX, CoreML और MLX मॉडलों के साथ काम करते हैं \
            Hugging Face, LangChain, FastAPI, Django और Pydantic के माध्यम से। \
            डिप्लॉयमेंट लक्ष्य Vercel, Cloudflare, Supabase, Gunicorn और Uvicorn हैं। \
            हम Whisper, mlx-whisper, Auris, Claude, Anthropic और OpenAI उपकरणों का उपयोग करते हैं \
            macOS, iOS, iPadOS पर Xcode, Swift, SwiftUI के साथ Apple Silicon पर।
            """,

        .uk: """
            Це чітка, добре структурована транскрипція. \
            Ми деплоїмо на PostgreSQL, MySQL, MongoDB, Redis та Elasticsearch. \
            Стек використовує Kubernetes, Docker, nginx, Terraform та CI/CD через GitHub. \
            Автентифікація використовує OAuth, JWT, CORS та CSRF-захист. \
            API-шар використовує GraphQL, gRPC, WebSocket та REST API ендпоінти. \
            Фронтенд побудований на JavaScript, TypeScript, React, Next.js, \
            Vue.js, Svelte та Node.js, стилізований з Tailwind CSS та webpack. \
            Ми дотримуємося стандартів доступності ARIA та WCAG у HTML5 та CSS Grid макетах. \
            Машинне навчання використовує PyTorch, TensorFlow, scikit-learn, NumPy та SciPy. \
            Ми працюємо з моделями LLaMA, GPT-4, DALL-E, LoRA, RAG, RLHF, ONNX, CoreML та MLX \
            через Hugging Face, LangChain, FastAPI, Django та Pydantic. \
            Деплой іде на Vercel, Cloudflare, Supabase, Gunicorn та Uvicorn. \
            Ми використовуємо Whisper, mlx-whisper, Auris, Claude, Anthropic та OpenAI інструменти \
            на macOS, iOS, iPadOS з Xcode, Swift, SwiftUI на Apple Silicon.
            """,

        .pl: """
            To jest jasna, dobrze ustrukturyzowana transkrypcja. \
            Deployujemy na PostgreSQL, MySQL, MongoDB, Redis i Elasticsearch. \
            Stack używa Kubernetes, Docker, nginx, Terraform i CI/CD przez GitHub. \
            Uwierzytelnianie używa OAuth, JWT, CORS i ochrony CSRF. \
            Warstwa API używa GraphQL, gRPC, WebSocket i endpointów REST API. \
            Frontend jest zbudowany z JavaScript, TypeScript, React, Next.js, \
            Vue.js, Svelte i Node.js, stylizowany z Tailwind CSS i webpack. \
            Stosujemy standardy dostępności ARIA i WCAG w układach HTML5 i CSS Grid. \
            Uczenie maszynowe używa PyTorch, TensorFlow, scikit-learn, NumPy i SciPy. \
            Pracujemy z modelami LLaMA, GPT-4, DALL-E, LoRA, RAG, RLHF, ONNX, CoreML i MLX \
            przez Hugging Face, LangChain, FastAPI, Django i Pydantic. \
            Deploy celuje w Vercel, Cloudflare, Supabase, Gunicorn i Uvicorn. \
            Używamy Whisper, mlx-whisper, Auris, Claude, Anthropic i narzędzi OpenAI \
            na macOS, iOS, iPadOS z Xcode, Swift, SwiftUI na Apple Silicon.
            """,

        .tr: """
            Bu açık, iyi yapılandırılmış bir transkriptir. \
            PostgreSQL, MySQL, MongoDB, Redis ve Elasticsearch üzerine deploy yapıyoruz. \
            Yığın Kubernetes, Docker, nginx, Terraform ve GitHub üzerinden CI/CD kullanıyor. \
            Kimlik doğrulama OAuth, JWT, CORS ve CSRF koruması kullanıyor. \
            API katmanı GraphQL, gRPC, WebSocket ve REST API endpoint'leri kullanıyor. \
            Frontend JavaScript, TypeScript, React, Next.js, \
            Vue.js, Svelte ve Node.js ile oluşturulmuş, Tailwind CSS ve webpack ile stillenmiştir. \
            HTML5 ve CSS Grid düzenlerimizde ARIA ve WCAG erişilebilirlik standartlarını takip ediyoruz. \
            Makine öğrenimi PyTorch, TensorFlow, scikit-learn, NumPy ve SciPy kullanıyor. \
            LLaMA, GPT-4, DALL-E, LoRA, RAG, RLHF, ONNX, CoreML ve MLX modelleriyle \
            Hugging Face, LangChain, FastAPI, Django ve Pydantic üzerinden çalışıyoruz. \
            Deploy hedefleri Vercel, Cloudflare, Supabase, Gunicorn ve Uvicorn. \
            Whisper, mlx-whisper, Auris, Claude, Anthropic ve OpenAI araçlarını \
            macOS, iOS, iPadOS üzerinde Xcode, Swift, SwiftUI ile Apple Silicon'da kullanıyoruz.
            """,
    ]

    static func forLanguage(_ language: AppLanguage) -> String {
        prompts[language] ?? prompts[.en]!
    }
}
