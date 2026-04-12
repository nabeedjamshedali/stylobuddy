const looks = [
  {
    id: 1,
    name: 'Linear Mono',
    category: 'Minimalist',
    aspect: 'aspect-[3/4]',
    src: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDfWCmmOF5xncyhGVSuu9f3RdDGhWorQgHJZ3uxL5BMQP052CVe1yRCjHPjq7QNzb98WSXSDyih9rYeAAx9qA8tLLJs-uI3CSbTX1Wuo7xb-g3ZIgUSYRd1pKYuXeDtGUxOcN5lU1GcxelXVi5k1iaLTnLs44RMjIJ-Sd4OLXsHFuuzkTXaXS7RADrYTCFkoopi89WrK09anNGtt_F4qMB7x6BdU8-RTKH88rSAiHQKW0Svm20Q0gHgIY59VHLXzNzwKwzRhYdx6v8s',
    alt: 'Linear Mono – structured cream linen shirt with wide-leg charcoal trousers',
  },
  {
    id: 2,
    name: 'Urban Armor',
    category: 'Streetwear',
    aspect: 'aspect-[2/3]',
    src: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAjjoGouVzSh--GYG2eO8ZXm8GRlKdJfvj8f3k1lUl6MwhUBHmFOlLGX8QsaKa9OPCr1fDSnwchB7Kg20AvO75MMsqr9jax0-OHtz67vrPXO9KDC2qQphSGrXrFr9_PwqIGygxqlDuJddajdesp8i7jSxYCHLqWEAZC38BQxNKrz001xBAT0t-YBFAzX6CzrFdVnlZTAgRVHGtf-4VxQaeCN-lEqdkFKQGsRIA7h4AbyFoN3gzxdwa2ugGQ4dSZIOM7ATzo-T7cwVz7',
    alt: 'Urban Armor – oversized black techwear jacket with cargo pants',
  },
  {
    id: 3,
    name: 'Verdant Spring',
    category: 'Tailored',
    aspect: 'aspect-[1/1]',
    src: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAw0w95jE-Z1aFQUmYHflVcG3yaeL5ICMk2IJr5WnzPYYlkINUL7nLBza3VLQXy93wPuQnvQBvj2Zq1ceTaAWTtxpoax7Gnb6oU4MtpCHyMH1B3Zq-I1mu7NNgUHt1Y9OjoDark_uUzCJvpTpn96sIRBmBh4t59aawfDAEduxH7XzJtXWhYFXP1m_KVETiARoXkjpTdZdrTyKMCs84JeVS_jrNoalTeUancFhsu47LInTpMXrSk3xry6yw7hlbvwEPx2l3v7rEGsMKJ',
    alt: 'Verdant Spring – silk emerald green shirt with sand-colored chinos',
  },
  {
    id: 4,
    name: 'Texture Play',
    category: 'Avant-Garde',
    aspect: 'aspect-[4/5]',
    src: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBoGFNRt7boowGjFU-SwkdVpMbIUivuhUM7H4kJsCjnr0JbJdaKqIzc6opw9rnu_404Saqdsyj86vF4KjMCHFAbtuSrnqfwIaGNBCUtOEukiypDXvHc0BW7gqGUUx5Us_iP3RpNsUslNpmUSdARCxPU-_Y89wn2ZbsHZQxSJ9D3F2J6rkX7NzRDnGMmMyQ_6AjplWxHYq-3-FGGtNS0a7W9rSpZbEMua_5ZvgqV7-JmUczXGNfT67Hi76HhwaKUPJJ-p24XaeU5MovL',
    alt: 'Texture Play – sheer mesh top with vintage leather vest and pinstripe trousers',
  },
  {
    id: 5,
    name: 'Desert Nomad',
    category: 'Minimalist',
    aspect: 'aspect-[3/2]',
    src: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAp3fwffkxW1aCoFWGKf-2QwPnK5vz31oEK-bEOmxrOQsa4WLGOuiTgWL_xwGU8Rb0d_wihIYu8oTJlBaxDsIBm8-UC3YZ5CkM6Arnn_AW3miADgfkoRdPktb2KAsFXvQ6tK2f68EOJxyGHFvxmS7BXMjfjVvNPUqcanX3j-wKnZdqVAseZuccRfaWwTvAsSR4a_pHFCgxUnyGRCCGke-WRA971A-6h4uFOYI8fYGijth4sQbb__kMw5Nl8NkuW9LwAoxv2dPP6A1VA',
    alt: 'Desert Nomad – flowing white linen in a desert landscape',
  },
  {
    id: 6,
    name: 'Electric Indigo',
    category: 'Streetwear',
    aspect: 'aspect-[2/3]',
    src: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDoXn7GwdAIIuPI5fUSb7AY7oglA-mXfQh6_PrYZDOutkd8ieyg7SswJnACXeckGiEhvdFmzUYNmYBtlUMGbV1X08O-H3BGcNtyjRde1ChMcSD0g4qLZiM9J6CLAY8HF6HY7i7wpHRGmyN2eshGzdpM-SPq5c4B3PZeSwl54lZpB-dTFpu2MO9z2XgeoEVKWaTbQS74KQMkLaGji845hGnGLOOYJT2vDAdmuykCgStU3n5IBRlcHl1PuGm43kSEna363dVkhweCCMT_',
    alt: 'Electric Indigo – cobalt blue knit sweater with metallic silver trousers',
  },
]

const filters = ['All Styles', 'Minimalist', 'Streetwear', 'Avant-Garde', 'Tailored']

export default function ExplorePage() {
  return (
    <main className="pt-32 pb-24 px-6 md:px-12 max-w-[1440px] mx-auto">
      {/* Header */}
      <header className="mb-20 max-w-3xl">
        <h1 className="text-[3.5rem] font-extrabold font-headline leading-[1.1] tracking-tight mb-6 text-on-surface">
          Curated{' '}
          <span className="text-outline-variant font-light italic">
            Inspirations
          </span>
        </h1>
        <p className="text-on-surface-variant max-w-xl font-light leading-relaxed text-base">
          A digital atelier showcasing the intersection of form and texture.
          Explore our seasonal lookbook of meticulously paired silhouettes.
        </p>
      </header>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 mb-16">
        {filters.map((filter, i) => (
          <button
            key={filter}
            className={`px-8 py-2.5 rounded-full text-[0.6875rem] uppercase tracking-[0.1rem] transition-colors duration-[400ms] ${
              i === 0
                ? 'bg-secondary text-on-secondary font-bold'
                : 'bg-surface-container hover:bg-surface-container-high text-on-surface-variant'
            }`}
          >
            {filter}
          </button>
        ))}
      </div>

      {/* Masonry Gallery */}
      <div className="masonry-grid gap-8">
        {looks.map((look) => (
          <div key={look.id} className="editorial-image-container group relative">
            <div
              className={`overflow-hidden rounded-xl bg-surface-container-low ${look.aspect}`}
            >
              <img
                src={look.src}
                alt={look.alt}
                className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-[400ms]" />
            </div>
            <div className="mt-4 flex justify-between items-start">
              <div>
                <h3 className="font-headline font-bold text-lg">{look.name}</h3>
                <div className="flex gap-2 mt-1">
                  <span className="text-[0.625rem] uppercase tracking-widest text-outline">
                    {look.category}
                  </span>
                </div>
              </div>
              <button className="p-2 rounded-full border border-outline-variant/20 hover:bg-secondary/10 transition-colors">
                <span className="material-symbols-outlined text-sm">
                  bookmark
                </span>
              </button>
            </div>
          </div>
        ))}
      </div>
    </main>
  )
}
