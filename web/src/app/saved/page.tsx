export default function SavedStylesPage() {
  return (
    <main className="pt-32 pb-24 px-6 md:px-12 max-w-[1440px] mx-auto">
      {/* Editorial Header */}
      <header className="mb-16 md:mb-24 flex flex-col md:flex-row md:items-end justify-between gap-8">
        <div className="max-w-2xl">
          <span className="font-label uppercase tracking-[0.2rem] text-[0.6875rem] text-secondary font-bold mb-4 block">
            Archive 2024
          </span>
          <h1 className="font-headline font-extrabold text-5xl md:text-7xl tracking-tighter text-on-surface leading-none">
            Saved <br />{' '}
            <span className="text-outline-variant">Styles</span>
          </h1>
          <p className="mt-8 text-on-surface-variant font-light text-lg max-w-md">
            Your personal atelier of curated ensembles and AI-matched
            inspirations.
          </p>
        </div>
        <div className="flex gap-4">
          <button className="px-6 py-3 rounded-full border border-outline-variant/20 hover:bg-surface-container transition-all duration-[400ms] font-label text-xs uppercase tracking-widest flex items-center gap-2">
            <span className="material-symbols-outlined text-sm">tune</span>{' '}
            Filter
          </button>
          <button className="px-8 py-3 rounded-full bg-primary text-on-primary hover:bg-primary-dim transition-all duration-[400ms] font-label text-xs uppercase tracking-widest">
            Create New
          </button>
        </div>
      </header>

      {/* Asymmetric Bento Grid */}
      <div className="grid grid-cols-1 md:grid-cols-12 gap-8 items-start">
        {/* Item 1: Large Featured */}
        <div className="md:col-span-8 group">
          <div className="relative aspect-[16/10] overflow-hidden rounded-xl bg-surface-container-low transition-transform duration-700 ease-[cubic-bezier(0.2,0,0,1)] group-hover:scale-[1.01]">
            <img
              alt="Urban Nomad Ensemble"
              className="w-full h-full object-cover"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuChle3559RIuuP_jWCZjo7PtY1EC13e1FExVRDsoRymCex3jAFM7kKZj5c-QskVrOn9tJe2RgJZej8tYumPnFpeLb2vpoMIAWstSxO0jr9kRYnKRi0RWfAftBEnrvW5UJiZNmLR1iOlnNkmfLIFkmTU5M7PQHOoXDOyauls8K9U_qq4e9vsY3lFcrNimi3GhOC_SwBtmX9qwiiUnu-pXOXr4lGs9beWK-2K8ow5-OXY-1pK5aJfbfnks2Ox1g_UXEo5n0PL7uLAP73Q"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500 flex flex-col justify-end p-10">
              <div className="flex justify-between items-end">
                <div>
                  <h3 className="text-white font-headline text-2xl font-bold">
                    Urban Nomad Ensemble
                  </h3>
                  <p className="text-white/70 font-light mt-2">
                    Saved 2 days ago
                  </p>
                </div>
                <div className="flex gap-3">
                  <button className="w-12 h-12 rounded-full bg-white/20 backdrop-blur-md text-white flex items-center justify-center hover:bg-white hover:text-on-surface transition-all">
                    <span className="material-symbols-outlined">share</span>
                  </button>
                  <button className="w-12 h-12 rounded-full bg-white/20 backdrop-blur-md text-white flex items-center justify-center hover:bg-error-container hover:text-on-error-container transition-all">
                    <span className="material-symbols-outlined">delete</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Item 2: Vertical */}
        <div className="md:col-span-4 group">
          <div className="relative aspect-[3/4] overflow-hidden rounded-xl bg-surface-container-low transition-transform duration-700 ease-[cubic-bezier(0.2,0,0,1)] group-hover:scale-[1.01]">
            <img
              alt="Midnight Gala"
              className="w-full h-full object-cover"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuBo3QdOCLe1iLWynbZuo2JHmsObL2BnYPjLDjNDToZpGZuVomL1cxxSGoz_CXOM9YVpqRxV1vR8ORqeghR4GVYP0vTnmIqTzwTlbFbTDCOzJlCRBxNN8j_O0pMyzJlJ0eB8aHwEKhxF12wiOn_AXM5lekdEqDkkyP2Fz5CHUhfSx6Ifhv3tvn6xreSKRxnrdIs7RJ51OGY0eO0mhuBCevSEauRqGDIaZApKhYCBmhri3r669c4PHUArta9XvR5Zlbj3K4GdI9nTyoze"
            />
            <div className="absolute top-6 right-6">
              <span className="px-3 py-1 bg-white/70 backdrop-blur-xl rounded-full text-[0.625rem] font-bold uppercase tracking-wider">
                Formal
              </span>
            </div>
            <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500 flex flex-col justify-end p-8">
              <div className="flex justify-between items-center">
                <h3 className="text-white font-headline font-bold">
                  Midnight Gala
                </h3>
                <button className="material-symbols-outlined text-white">
                  more_vert
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Item 3: Square */}
        <div className="md:col-span-4 group">
          <div className="relative aspect-square overflow-hidden rounded-xl bg-surface-container-low transition-transform duration-700 ease-[cubic-bezier(0.2,0,0,1)] group-hover:scale-[1.01]">
            <img
              alt="Linen Breeze"
              className="w-full h-full object-cover"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuAKGQSIknCX5SBx0ludKWSBw0wbvIjPJ20_xAhj3g3Hg6YtsDVE-TS2ZLubMJAPZnMiZpEXYv8Qb9DTmQX4BJFZqJ0QJsrpjhQsvBhYedaIQxBWMigA-U9JKYxn3uL0uzpTMcX5Sz-Hx7TOIDs_5RVO31FpJzvmGMXrR2KGLBLYP8wn8BEL8izx2dNPvDDnPSK_6tCedCTxbR1iPT3blx5JhGilmUSWZi2oEkEOSnZ6vLbRluz4H4riIZNMNHJFAShgsz8OK-azLKZL"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500 flex flex-col justify-end p-8">
              <div className="flex justify-between items-center">
                <h3 className="text-white font-headline font-bold">
                  Linen Breeze
                </h3>
                <div className="flex gap-2">
                  <button className="material-symbols-outlined text-white text-sm">
                    share
                  </button>
                  <button className="material-symbols-outlined text-white text-sm">
                    delete
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Item 4: Wide */}
        <div className="md:col-span-8 group">
          <div className="relative aspect-[21/9] overflow-hidden rounded-xl bg-surface-container-low transition-transform duration-700 ease-[cubic-bezier(0.2,0,0,1)] group-hover:scale-[1.01]">
            <img
              alt="Active Pulse"
              className="w-full h-full object-cover"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuD8B8i7lKU5mNWjz19uzCEyc5tGdKmZlBmhAQrck2imsZeIW7BkuoOGUQ1nHGRTeb2fVQY-3rYbu58F-dZ3t2gw1umuwTt1itQTF2o0KskBJVHDKPsBXQodf7mLgRwLLXN0SUDMXgnVcexWAntt9A3OugbYVJ0trI6KOCm1TodqMCA20oBHnK4bEhqMQFzqgXcTEJFrHtUN8SyDm3IzxVdlMf9g3_kUwWZMOQjz2jAEfd2EA2v1RToqofaztPyWOD1bwsQpGyHYqlOX"
            />
            <div className="absolute inset-0 bg-gradient-to-r from-black/40 to-transparent p-10 flex flex-col justify-center">
              <h3 className="text-white font-headline text-3xl font-extrabold tracking-tight">
                Active Pulse
              </h3>
              <p className="text-white/80 font-light max-w-xs mt-2">
                The ultimate performance layer for city mornings.
              </p>
              <div className="mt-6 flex gap-4">
                <button className="bg-white text-on-surface px-6 py-2 rounded-full font-label text-[0.6875rem] uppercase tracking-widest hover:bg-secondary-container transition-colors">
                  Edit Look
                </button>
                <button className="bg-white/20 backdrop-blur-md text-white px-6 py-2 rounded-full font-label text-[0.6875rem] uppercase tracking-widest hover:bg-white/30 transition-colors">
                  Share
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Item 5: Portrait */}
        <div className="md:col-span-4 group">
          <div className="relative aspect-[3/4] overflow-hidden rounded-xl bg-surface-container-low transition-transform duration-700 ease-[cubic-bezier(0.2,0,0,1)] group-hover:scale-[1.01]">
            <img
              alt="Grey Scale"
              className="w-full h-full object-cover"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuBF4kQPcGjbzfl4on9Tfpn7jBmaTa721OZx2Dk-UKS1qxxE206t7zNnVV44oOEyGj23u8IVbwUkTk-4kCjoilUUWn_KsIqdjfjt1xeMeTGvAZ-SKpnP2DYsN9K3PfupZ4mH5vpWPbtXr_y1WAR5ZmKCP_F3AVKyNcfARG2Th-NNJW2EPy7kQ2rUENVYDDib2UT7D-is4cqSScRNwUSu_5RZv5YH49GMOWwcAbCPC6iDiKN0LfmxgtE8jZvicMfG4OZvJmP_jqjMJR_N"
            />
            <div className="absolute bottom-0 left-0 right-0 p-8 bg-surface-container-lowest/90 backdrop-blur-lg transform translate-y-full group-hover:translate-y-0 transition-transform duration-500">
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="font-headline font-bold text-on-surface">
                    Grey Scale
                  </h3>
                  <p className="text-xs text-on-surface-variant uppercase tracking-widest mt-1">
                    4 Items
                  </p>
                </div>
                <button className="text-error material-symbols-outlined">
                  delete
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Item 6: Tall */}
        <div className="md:col-span-4 group">
          <div className="relative aspect-[4/5] overflow-hidden rounded-xl bg-surface-container-low transition-transform duration-700 ease-[cubic-bezier(0.2,0,0,1)] group-hover:scale-[1.01]">
            <img
              alt="Heritage Modern"
              className="w-full h-full object-cover"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuATtwRQEBSW9Dq115Hx2ER3hUjITjMetogz7oglUvQmC-sl5rxnrLjfVX3HTcr4U2chbYMSf_zVoFbUbEWplqqavbfZBu9cDn8X6gjCOHNkV6GoZdhyMuyWNT6GhE51A6OFzcQQmowBhy-YGk72hExAlm9-MrpDKRYoj6pfoPo5FPIQ96WxC9zjDLEdLXGhU5uQ0R4Ksx-Vu2uHkneQJIcX4eyu50e0P26hMTd4RJUbq1HkQcbjhTgMIeo3ARzP_TD23PXI0-MVTq_6"
            />
            <div className="absolute inset-0 p-8 flex flex-col justify-between opacity-0 group-hover:opacity-100 transition-opacity duration-500">
              <div className="flex justify-end">
                <span className="w-10 h-10 rounded-full bg-white/20 backdrop-blur-md text-white flex items-center justify-center">
                  <span
                    className="material-symbols-outlined"
                    style={{ fontVariationSettings: "'FILL' 1" }}
                  >
                    bookmark
                  </span>
                </span>
              </div>
              <div className="bg-black/40 backdrop-blur-md p-4 rounded-lg">
                <h3 className="text-white font-headline font-bold">
                  Heritage Modern
                </h3>
                <div className="flex justify-between items-center mt-3">
                  <button className="text-white/60 hover:text-white transition-colors">
                    <span className="material-symbols-outlined text-sm">
                      ios_share
                    </span>
                  </button>
                  <button className="text-white/60 hover:text-white transition-colors">
                    <span className="material-symbols-outlined text-sm">
                      delete
                    </span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Item 7: Square Gallery */}
        <div className="md:col-span-4 group">
          <div className="relative aspect-square overflow-hidden rounded-xl bg-surface-container-low transition-transform duration-700 ease-[cubic-bezier(0.2,0,0,1)] group-hover:scale-[1.01]">
            <img
              alt="Golden Hour Set"
              className="w-full h-full object-cover"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuBt28X2VVxij7YBsD1d6W4_dlwspDdNB50y6OxTJH-rMfZIZQ5HYMbeZEnmbUFf1VJhV7Pljq4tbP3k4Tr9uBwEb3PUvjdaBhGpYCP09Y13GYmx8NAtPKjU-WZjJuLB9nxK8Jtv0vjd1QNo659IC6SShHSq8aPBMd1gPS6Htq6Tf2ErR1sUp5fFIkmbUAcn9k5yJUwxGV_fq9tl101eKLtdlyClaYyC2H7DlgVDITgVZ3nipAteIWCFJe4cEcT-6jN1eFXm-FlXGpH-"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500 flex items-end p-8">
              <p className="text-white font-headline text-lg font-bold">
                Golden Hour Set
              </p>
            </div>
          </div>
        </div>
      </div>
    </main>
  )
}
