package main

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"net/http"
	"os"
	"time"

	"github.com/spf13/cobra"
)

var (
	serverPort  = 8081
	iterate     int
	total_index = 0
	total_200   = 0

	initialDelay  int
	initial_delay time.Duration
	urls          = []string{
		"sappas01.atc.internal",
		"lampapasrp1.sap.lamosa.com",
		"laeddc01.sap.lamosa.com",
		"mtspwpcnsapvq11.sap.novis.cl",
		"samplprdsap01.sap.saamterminals.com",
		"ucmplcspsapvq11.sap.ucm.cl",
		"vp6pas01.atc.internal",
		"msldwecdsapvt11.tenant01.novis.cl",
		"cd1pas01.atc.internal",
		"laebkp01.sap.lamosa.com",
		"sksdwde0sapvq12.sap.novis.cl",
		"wj2pas01.atc.internal",
		"jwdpas01.atc.internal",
		"lhlmsjlmdbj.sap.lamosa.com",
		"pp2pas01.atc.internal",
		"lajpap01dr.sap.lamosa.com",
		"mtrpwcingrp.sap.metro.cl",
		"bchlbpop.sap.bcentral.cl",
		"lamdapasrd1.sap.lamosa.com",
		"rcdpasfiq.sap.rcdhotels.com",
		"lamqapasrq1.sap.lamosa.com",
		"lalpdc01dr.sap.lamosa.com",
		"pp1pas01.atc.internal",
		"llmsscsjp1dr.sap.lamosa.com",
		"skspwpr0sapvq12.sap.novis.cl",
		"llmspdb2jp1.sap.lamosa.com",
		"llmsplaasjcp.sap.lamosa.com",
		"bchdlscspod.sap.bcentral.cl",
		"engdwdc3sapvt11.sap.novis.cl",
		"llmsplasclp1.sap.lamosa.com",
		"sb2pas01.novislabs.internal",
		"cd4pas01.atc.internal",
		"bchqlpasqas.sap.bcentral.cl",
		"llmsplpaaep1.sap.lamosa.com",
		"wq2pas01.atc.internal",
		"BCHPLERPSAP05l.SAP.BCENTRAL.CL",
		"llmspdb2jcp1.sap.lamosa.com",
		"sksqwts0sapvq12.sap.novis.cl",
		"llmspasjcpdr.sap.lamosa.com",
		"bchplpa1pop.sap.bcentral.cl",
		"llmsqpasjcq1.sap.lamosa.com",
		"BCHPLERPSAP01.sap.bcentral.cl",
		"lhlmsslmpas.sap.lamosa.com",
		"nvsdwdecsql.sapnvs.novis.cl",
		"nvspwcinprc.sapnvs.novis.cl",
		"embplhccsapvq11.sap.embonor.cl",
		"llmsplaasjp1.sap.lamosa.com",
		"lhlmsjlmscs.sap.lamosa.com",
		"lalddc01.sap.lamosa.com",
		"rcdpasdpo.sap.rcdhotels.com",
		"llmsplerslp1.sap.lamosa.com",
		"wj3pas01.atc.internal",
		"laeqdc01.sap.lamosa.com",
		"mtsdwdcnsapvq11.sap.novis.cl",
		"valmsplcp201.sap.lamosa.com",
		"nvsqwcintec.sapnvs.novis.cl",
		"lacqdc01.sap.lamosa.com",
		"hw3pas01.atc.internal",
		"bchqlscspoq.sap.bcentral.cl",
		"sksdwde0sapvt11.sap.novis.cl",
		"lacpdc01dr.sap.lamosa.com",
		"ucmdldposapvq11.sap.ucm.cl",
		"rcdpasdbw.sap.rcdhotels.com",
		"ucmqlqposapvq11.sap.ucm.cl",
		"sptqlcinqas.sap.saamterminals.com",
		"lawddc01.sap.lamosa.com",
		"sapsol01.novislabs.internal",
		"embplhcisapvq11.sap.embonor.cl",
		"lhlmsjlmpas.sap.lamosa.com",
		"samqlcinqas.sap.saam.cl",
		"mslpwecpsapvt11.tenant01.novis.cl",
		"ha7pas01.atc.internal",
		"sksqwts0sapvt11.sap.novis.cl",
		"vp6ascs.atc.internal",
		"slmpas01.atc.internal",
		"llmspscsjcp1.sap.lamosa.com",
		"bchpla04erp.sap.bcentral.cl",
		"vhbmnshqas01.gcp.banorte.com",
		"rcdpasfid.sap.rcdhotels.com",
		"lawqdc01.sap.lamosa.com",
		"po0pas01.atc.internal",
		"nvspwspasapvq11.servicio.novis.cl",
		"engpwpc3sapvt11.sap.novis.cl",
		"wj3ascs.atc.internal",
		"lampwscszp1.sap.lamosa.com",
		"nvspwspjsapvq11.servicio.novis.cl",
		"llmsplappjp1.sap.lamosa.com",
		"mtsqwtcnsapvq11.sap.novis.cl",
		"llmspapp15.sap.lamosa.com",
		"llmspapp14.sap.lamosa.com",
		"po9pas01.atc.internal",
		"bchpla03erp.sap.bcentral.cl",
		"lajpap01.sap.lamosa.com",
		"samplcinprd.sap.saam.cl",
		"valmsplep111.sap.lamosa.com",
		"lalpdc01.sap.lamosa.com",
		"nvsdwcindec.sapnvs.novis.cl",
		"ftldlpasfdx.aws.fertinal.com",
		"lajdap01.sap.lamosa.com",
		"rcdhdbdev.sap.rcdhotels.com",
		"wd1pas01.atc.internal",
		"bchqlpaspoq.sap.bcentral.cl",
		"llmsplpasjcp.sap.lamosa.com",
		"sffpwprssapvt12.sap.oticsofofa.cl",
		"rsndwdeksapvq11.tenant01.novis.cl",
		"sptslcindev.sap.saamterminals.com",
		"rcdpastst.sap.rcdhotels.com",
		"sffdwdessapvt11.sap.oticsofofa.cl",
		"jwdascs.atc.internal",
		"j1dascs.atc.internal",
		"rcdpasdev.sap.rcdhotels.com",
		"vhbmnshpas01.gcp.banorte.com",
		"llmsqdbaeq1.sap.lamosa.com",
		"llmsplascjp1.sap.lamosa.com",
		"htfplprdpas.sap.hortifrut.cl",
		"llmsqscsjwq1.sap.lamosa.com",
		"rcdhdbdbw.sap.rcdhotels.com",
		"llmsplersjp1.sap.lamosa.com",
		"wq2pas01.atc.internal",
		"nvsdwascdec.sapnvs.novis.cl",
		"llmspldbalp1.sap.lamosa.com",
		"llmspapp16.sap.lamosa.com",
		"sap-prod-3.sap.novis.cl",
		"llmsqscsjcq1.sap.lamosa.com",
		"lmspastes.sap.lamosa.com",
		"j1dpas01.atc.internal",
		"llmspassbx.sap.lamosa.com",
		"htfplprdsap03.sap.hortifrut.cl",
		"llmsscsjcpdr.sap.lamosa.com",
		"mslqwecqsapvt11.tenant01.novis.cl",
		"rcdhdbtst.sap.rcdhotels.com",
		"bchplpa2pop.sap.bcentral.cl",
		"rsnqwteksapvq11.tenant01.novis.cl",
		"skspwpr0sapvt11.sap.novis.cl",
		"samslcindev.sap.saam.cl",
		"engqwtc3sapvt11.sap.novis.cl",
		"wj2ascs.atc.internal",
		"sptslascdev.sap.saamterminals.com",
		"wq3pas01.atc.internal",
		"htfplprdasc.sap.hortifrut.cl",
		"llmsqpasjwq1.sap.lamosa.com",
		"embplsprsapvq11.sap.embonor.cl",
		"sffqwqassapvt11.sap.oticsofofa.cl",
		"OXQQWTCTSAP01.sap.oxiquim.cl",
		"CFOPWPCGSAPVT13.sap.corfo.cl",
	}

	dnsResolverIP        = "100.127.255.254:53"
	dnsResolverProto     = "udp"
	dnsResolverTimeoutMs = 5000
	encoder              json.Encoder
)

var rootCmd = &cobra.Command{
	Use:   "http",
	Short: "A simple http test client",
	Long:  "A simple http test client",
}

var runCmd = &cobra.Command{
	Use:   "run",
	Short: "run tests",
	Long:  "run tests",
	Run:   runTest,
}

func init() {
	rootCmd.AddCommand(runCmd)
	runCmd.Flags().IntVar(&iterate, "iterate", 1, "number of test iterations")
	runCmd.Flags().IntVar(&initialDelay, "initial-delay", 5, "initial delay to start the test in seconds")
}

func calculate(s float64, t float64, p float64) float64 {
	v := ((s / t) * 100)
	r := math.Pow(10, float64(p))
	return math.Round(v*r) / r
}

func runTest(cmd *cobra.Command, args []string) {

	initial_delay = time.Duration(initialDelay)
	time.Sleep(initial_delay * time.Second)

	httpClient := &http.Client{
		Transport: &http.Transport{
			TLSHandshakeTimeout: 10 * time.Second,
			TLSClientConfig:     &tls.Config{InsecureSkipVerify: true},
		},
		Timeout: 5 * time.Second,
	}

	filePath := "/var/log/http_test.json"
	file, err := os.OpenFile(filePath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		log.Printf("Error opening file:", err)
		return
	}
	defer file.Close()

	for i := 0; i <= iterate; i++ {

		for j, url := range urls {

			requestURL := fmt.Sprintf("https://%s:%d/health-checks", url, serverPort)
			req, err := http.NewRequest(http.MethodGet, requestURL, nil)
			if err != nil {
				log.Printf("client: could not create request: %s\n", err)
				continue
			}
			req.Close = true

			resp, err := httpClient.Do(req)
			if err != nil {
				log.Printf("client: error making http request: %s\n", err)
				continue
			}

			defer resp.Body.Close()
			total_index = j + 1 + i*len(urls)
			encoder = *json.NewEncoder(file)
			encoder.Encode(total_index)
			encoder.Encode(resp.StatusCode)
			encoder.Encode(resp.Header["Date"])
			encoder.Encode(resp.Request.URL.Host)
			if resp.StatusCode == 200 {
				total_200++
			}
		}

	}

	availability := calculate(float64(total_200), float64(total_index), 3)
	if availability > 99.950 {
		encoder.Encode(fmt.Sprintf("Test Passed with availability rate of %.3f percent", availability))
	} else {
		encoder.Encode(fmt.Sprintf("Test Failed with availability rate of %.3f percent", availability))
	}

}

func main() {

	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

}
