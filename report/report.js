document.addEventListener("DOMContentLoaded", function() {
    let hiddenTestCases = JSON.parse(localStorage.getItem("hidden-test-cases") || "[]");
    const searchInput = document.getElementById("search-input");
    searchInput.value = localStorage.getItem("search-input-value") || "";
    const filterTestCases = () => {
        const searchText = searchInput.value.toLowerCase();
        const testCases = document.getElementsByClassName("test-case-result");
        for (let i = 0; i < testCases.length; i++) {
            const testCase = testCases[i];
            const testCaseText = testCase.textContent.toLowerCase();
            const testCaseName = testCase.querySelector(".test-case-name").textContent;
            if (hiddenTestCases.includes(testCaseName) || (searchText.length > 0 && testCaseText.includes(searchText))) {
                testCase.classList.add("hide");
            } else {
                testCase.classList.remove("hide");
            }
        }

        localStorage.setItem("search-input-value", searchInput.value);
    };

    const copyLink = (prefix, el) => (event) => {
        event.preventDefault();
        navigator.clipboard.writeText(`${prefix}${el.textContent}`);
    };

    const hideTestCase = (testCase) => (event) => {
        event.preventDefault();
        const testCaseName = testCase.querySelector(".test-case-name").textContent;
        if (testCase.classList.contains("hide")) {
            testCase.classList.remove("hide");
            hiddenTestCases = hiddenTestCases.filter(hiddenTestCaseName => hiddenTestCaseName !== testCaseName);
        } else {
            testCase.classList.add("hide");
            hiddenTestCases.push(testCaseName);
        }
        localStorage.setItem("hidden-test-cases", JSON.stringify(hiddenTestCases));
    };

    const testCases = document.querySelectorAll(".test-case-result");

    testCases.forEach((testCase) => {
        const testCaseName = testCase.querySelector(".test-case-name");
        testCaseName.addEventListener("click", copyLink('', testCaseName));
        testCase.querySelector(".run-link").addEventListener("click", copyLink('zig build run -- ', testCaseName));
        testCase.querySelector(".hide-link").addEventListener("click", hideTestCase(testCase));
    });
    searchInput.addEventListener("input", filterTestCases);
    filterTestCases();

    const showHidden = (event) => {
        const reportBody = document.querySelector(".report-body");
        reportBody.classList.toggle("show-hidden", event.target.checked);
    };
    document.getElementById("show-hidden").addEventListener("change", showHidden);
    showHidden();
});