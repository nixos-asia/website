<apply template="base">
    <bind tag="body-main">
        <div class="container max-w-screen-md mx-auto mt-8 flex flex-col items-center justify-center">
            <bind tag="cardClass">rounded-lg shadow-md m-4 bg-white </bind>
            <bind tag="cardSmallClass">rounded-lg hover:shadow-md m-4 hover:bg-white flex-shrink-0 </bind>
            <bind tag="linkClass">underline</bind>

            <!-- Topmost card -->
            <div style="max-width: 40em;"
                class="${cardClass} px-4 py-6 flex flex-col items-center justify-center space-y-4">
                <div class="w-32 hover:w-64 flex-shrink-0">
                    <ema:metadata>
                        <with var="template">
                            <a href="en" title="Visit the English version of NixOS Asia">
                                <img src="${value:iconUrl}" class="rounded-full object-cover">
                            </a>
                        </with>
                    </ema:metadata>
                </div>
            </div>
        </div>
    </bind>
</apply>