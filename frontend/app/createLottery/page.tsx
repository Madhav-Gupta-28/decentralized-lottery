"use client";

declare global {
  interface Window {
    ethereum: any;
  }
}

import React , {useState , useContext , useEffect , useRef} from 'react'
import LotteryMarketplace from '@/components/LotteryPlace/lotteryMarketplace';

import ConnectButtonWrapper from '@/components/ConnectWalletButtonWrapper/buttonWrapper';
import { Button , Box, Center , Heading, VStack , HStack ,Spinner, ChakraProvider } from '@chakra-ui/react';
import axios from 'axios'
import Style from "./createLottery.module.css";
import { ethers } from 'ethers'
import Link from 'next/link';
import {aiftMarketplaceAddress  , aiftMarketplaceabi} from "../../constant.js";
import {ExternalLinkIcon} from "@chakra-ui/icons"


import NFTTile from '@/components/NFTTile/NFTTile';


export const CreateLottery = () => {
  
    const [nftArray , setnftArray] = useState<any>();
    const [loading , setloading] = useState(false)

    
    const fetchMyNFTs = async() => {

        try{

            setloading(true)
            const accounts = await window.ethereum.request({
              method: 'eth_accounts'
            });
        
          const account = accounts[0]
        
            const provider = new ethers.providers.Web3Provider(window.ethereum)
            const signer = provider.getSigner()
            const aift = new ethers.Contract(aiftMarketplaceAddress, aiftMarketplaceabi, signer)
        
            const tx = await aift.fetchMYNFTs(account)
            const proposalsArray = Object.values(tx); 
            setnftArray(Object.values(tx));
            console.log('Reading tx--> ')
            console.log(tx)
            console.log( "NFT ARRAY -> " , nftArray)
            setloading(false)
        }catch(error){
            console.log('FetchMyNFTs Function Error -> ' , error)
        }

      }
    
      useEffect(() => {
        fetchMyNFTs()
      },[])


  return (
   <>
  <ConnectButtonWrapper/>
{/*   
        <ChakraProvider>
            <div className='h-full' style={{minHeight:'100vh' ,
    background: "linear-gradient(135deg, #426F4E 0%, #05101A 100%)"   , color:"#ff8700"}} >
        <Center justifyContent={'center'}>
        <VStack as='header' spacing='6' mt='8' wrap={'wrap'} justifyContent={'space-evenly'} p={'2'}>
            <Heading
              as='h1'
              fontWeight='700'
              fontSize='2rem'
              color={"#fff"}
              padding={"0.4rem 0.8rem"}
              margin={'2rem 0 '}
              
            >
             Profile
            </Heading>

            <div className={Style.thinwhiteborder} style={{marginBottom:'2rem'}} >
    </div>
   
          </VStack>
        </Center>
        <HStack wrap={'wrap'} justifyContent={'space-evenly'}>
        {loading ? 
                <Center h={'30vh'} justifyContent={'center'} >
                    <Spinner alignSelf={'center'} thickness='5px'speed='0.5s'emptyColor='gray.200'color='rgba(255, 255, 255, 0.90)'size='xl' />
                </Center>
                 :
              <HStack wrap={'wrap'} justifyContent={'space-evenly'}>
                {nftArray.length !== 0 ? 
                <div className="grid sm:grid-cols-2 w-fit md:grid-cols-3 lg:grid-cols-4 mx-auto pb-10 gap-6">
                {nftArray.map((items: any  ) => {
                  return (
                    <>   
                      {items.tokenURI && (
                        <div className="col-span-1 w-72 rounded-3xl border-2 pt-2.5 shadow-md hover:shadow-lg hover:shadow-black transition ease-in-out delay-150 shadow-black"  style={{border:"2px solid  rgba(255, 255, 255, 0.90) " }}>
                          <NFTTile tokenURI={items.tokenURI} proposalid={items.id.toString() } listed={items.listed} price={items.price.toString()} />
                        </div>
                      )}
                      <div style={{ color: '#fff' }}>
                      </div>
                    </>
                  );
                })}
              </div>
                :
                <Center  h={'50vh'}>
                <div className='message text-white'>No AIFT... Pretty Strange Create One <Link href='/mintNFT'><ExternalLinkIcon fontSize={"2rem"} /></Link> </div>
                </Center>
               
            }
              </HStack>
}

        </HStack>
    </div>
        </ChakraProvider> */}
   
    
   </>
  )
}


export default CreateLottery;