"use client"
import React , {useState , useEffect , useContext} from 'react'
import { HStack , Heading , Flex  , Spacer , Box , Menu , MenuButton ,MenuItem , MenuList} from '@chakra-ui/react';
import Link from 'next/link';
import Style from "./Header.module.css"
import { ConnectButton } from '@rainbow-me/rainbowkit';
import {Text} from '@chakra-ui/react';
import Image from 'next/image';


const Header = () => {
  
    return (
        <>
        <div>
            <header className="header ">
        <div className="container mx-auto px-4 py-4">
          <nav className="flex items-center justify-between">
            <div className="flex items-center">
              <a href="/" className=" font-bold text-2xl park3-heading ">
                <div className='flex h-full py-auto'> 
                <p className='h-full py-auto px-4'>NFTSweep</p>
                </div>
              </a>
            </div>
            <ul className="flex items-center space-x-6">
              <li>
              <Menu>
              <MenuButton className="a" as={Text} fontWeight="500" fontSize="lg" _hover={{ textDecoration: 'underline' , cursor:'pointer'}}>
              Lottery
              </MenuButton>
              <MenuList>
                <MenuItem className='header-link'>
                <Link className='header-link' href={'/createLottery'} >Create Lottery </Link>
                </MenuItem>
                <MenuItem><Link className='header-link' href={'/myproposals'} >Lottery Marketplace</Link></MenuItem>
              </MenuList>
            </Menu>
              </li>
              <li>
              <Menu>
              <MenuButton  className=' a'  as={Text} fontWeight="500" fontSize="lg" _hover={{ textDecoration: 'underline', cursor:'pointer' }}>
                Profile
              </MenuButton>
              <MenuList>
                <MenuItem>  <Link  className='header-link'  href={'/uploadassets'}>Participated Lottery</Link>  </MenuItem>
                <MenuItem> <Link   className='header-link' href={'/profile'}>Creater Dashboard</Link></MenuItem>
              </MenuList>
            </Menu>
              </li>
    
              <li>
              <Menu>
              <MenuButton  className=' a'  as={Text} fontWeight="500" fontSize="lg" _hover={{ textDecoration: 'underline', cursor:'pointer' }}>
                Marketplace
              </MenuButton>
              <MenuList>
                <MenuItem>  <Link  className='header-link'  target='_blank' href={'https://app.poply.xyz/'}>AIFT Marketplace</Link>  </MenuItem>
              </MenuList>
            </Menu>
              </li>
              <ConnectButton label='Connect Wallet' accountStatus="avatar"  chainStatus="icon" showBalance={{
    smallScreen: false,
    largeScreen: true,
  }}/>
            </ul>
          </nav>
        </div>
      </header>
        </div>

        <div className={Style.thinwhiteborder} ></div>
    
        </>
      )
}

export default Header